// MT Alchemy payment server: keeps the Stripe secret key off the web app.
// Run: node --env-file=.env server.js
const express = require('express');
const cors = require('cors');
const Stripe = require('stripe');

const key = process.env.STRIPE_SECRET_KEY || '';
if (!key.startsWith('sk_')) throw new Error('Set STRIPE_SECRET_KEY in payments_server/.env');
const stripe = Stripe(key);
const allowed = (process.env.ALLOWED_ORIGINS || '').split(',').map((s) => s.trim()).filter(Boolean);

const app = express();
app.use(express.json({ limit: '50kb' }));
app.use(cors({ origin: (origin, cb) => cb(null, !origin || allowed.includes(origin)) }));

app.get('/api/health', (_req, res) => res.json({ ok: true, mode: key.startsWith('sk_test_') ? 'test' : 'live' }));

// Creates a hosted Stripe Checkout page for one order.
app.post('/api/checkout-session', async (req, res) => {
  try {
    const { orderNumber, customerEmail, lines, returnUrl } = req.body || {};
    if (!/^[A-Za-z0-9-]{4,40}$/.test(orderNumber || '')) return res.status(400).json({ error: 'Invalid order number' });
    if (!Array.isArray(lines) || lines.length === 0 || lines.length > 50) return res.status(400).json({ error: 'No items' });
    const ret = new URL(returnUrl);
    if (!allowed.includes(ret.origin)) return res.status(400).json({ error: 'Return URL not allowed' });
    const line_items = lines.map((l) => {
      const unit = Math.round(Number(l.unitAmount) * 100);
      const qty = Math.round(Number(l.quantity));
      if (!(unit >= 100 && unit <= 10000000 && qty >= 1 && qty <= 1000)) throw new Error('Invalid line');
      return {
        quantity: qty,
        price_data: { currency: 'myr', unit_amount: unit, product_data: { name: String(l.name).slice(0, 120) } },
      };
    });
    const back = (status) => `${returnUrl}${returnUrl.includes('?') ? '&' : '?'}order=${encodeURIComponent(orderNumber)}&status=${status}&session_id={CHECKOUT_SESSION_ID}`;
    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      line_items,
      customer_email: customerEmail || undefined,
      client_reference_id: orderNumber,
      metadata: { orderNumber },
      payment_intent_data: { metadata: { orderNumber } },
      success_url: back('success'),
      cancel_url: back('cancelled'),
    });
    res.json({ id: session.id, url: session.url });
  } catch (e) {
    console.error('checkout-session', e.message);
    res.status(400).json({ error: e.message });
  }
});

// Lets the app confirm a payment with Stripe instead of trusting the browser.
app.get('/api/checkout-session/:id', async (req, res) => {
  try {
    const s = await stripe.checkout.sessions.retrieve(req.params.id, { expand: ['payment_intent.payment_method'] });
    const pm = s.payment_intent && s.payment_intent.payment_method;
    res.json({
      orderNumber: s.metadata.orderNumber,
      paymentStatus: s.payment_status, // paid | unpaid | no_payment_required
      status: s.status, // complete | open | expired
      amountTotal: s.amount_total / 100,
      currency: s.currency,
      paymentIntent: s.payment_intent && s.payment_intent.id,
      card: pm && pm.card ? `${pm.card.brand} •••• ${pm.card.last4}` : null,
    });
  } catch (e) {
    res.status(404).json({ error: 'Session not found' });
  }
});

const port = Number(process.env.PORT || 4242);
app.listen(port, () => console.log(`MT Alchemy payments server on http://localhost:${port} (${key.startsWith('sk_test_') ? 'TEST' : 'LIVE'} mode)`));
