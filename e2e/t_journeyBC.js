const L = require('./lib');
async function pay(page, method) {
  if (method === 'card') {
    await L.fill(page, 'Name on card', 'Aisha Rahman');
    await L.fill(page, 'Card number', '4242 4242 4242 4242');
    await L.fill(page, 'Expiry', '11/29');
    await L.fill(page, 'CVC', '321');
    await L.click(page, 'Pay RM', 'button', { wait: 4000 });
  } else {
    await L.click(page, 'Bank transfer', 'button', { wait: 600 });
    await L.click(page, 'Confirm order', 'button', { wait: 4000 });
  }
}
async function checkoutFields(page) {
  await L.fill(page, 'Full name', 'Aisha Rahman');
  await L.fill(page, 'Phone', '0123456789');
  await L.fill(page, 'Street address', '12 Jalan Bukit Bintang');
  await L.fill(page, 'City', 'Kuala Lumpur');
  await L.fill(page, 'State', 'Wilayah Persekutuan');
  await L.fill(page, 'Postcode', '55100');
  await L.fill(page, 'Country', 'Malaysia');
}
(async () => {
  let { browser, page } = await L.start(1280, 900);
  console.log('Journey B: digital product');
  await L.signIn(page, 'learner@mtalchemy.demo', 'AlchemyLearner!26');
  await L.open(page, '/store', 4000);
  await L.click(page, 'Digital', 'checkbox', { exact: true, wait: 800 });
  await L.click(page, 'Add Emotional Clarity Workbook to cart', 'button', { wait: 800 });
  await L.click(page, 'View cart', 'button', { wait: 2000 });
  await L.click(page, 'Proceed to Checkout', 'button', { wait: 3000 });
  await checkoutFields(page);
  await L.click(page, 'Continue to payment', 'button', { wait: 1500 });
  await pay(page, 'card');
  await L.expectText(page, 'Thank you for your order', 'digital order confirmation');
  await L.expectText(page, 'Status: Paid', 'digital order paid instantly');
  await L.click(page, 'Open Digital Product Library', 'button', { wait: 3000 });
  await L.expectText(page, 'Emotional Clarity Workbook', 'workbook in My Digital Products');

  console.log('Journey C: physical product, bank transfer');
  const before = (await L.fsList('products')).find(p => p.id === 'mindful-journal').stock;
  await L.open(page, '/store', 4000);
  await L.click(page, 'Add Mindful Reflection Journal to cart', 'button', { wait: 800 });
  await L.click(page, 'View cart', 'button', { wait: 2000 });
  await L.click(page, 'Proceed to Checkout', 'button', { wait: 3000 });
  await checkoutFields(page);
  await L.click(page, 'Continue to payment', 'button', { wait: 1500 });
  await pay(page, 'transfer');
  await L.expectText(page, 'Status: Pending', 'physical order pending (bank transfer)');
  const order = (await L.fsList('orders')).filter(o => o.customerEmail === 'learner@mtalchemy.demo' && o.paymentStatus === 'Pending').sort((a, b) => b.date.localeCompare(a.date))[0];
  const after = (await L.fsList('products')).find(p => p.id === 'mindful-journal').stock;
  L.check(after === before - 1, `stock reserved ${before} -> ${after}`);
  await browser.close();

  ({ browser, page } = await L.start(1400, 1000));
  await L.signIn(page, 'admin@mtalchemy.demo', 'AlchemyAdmin!26');
  await L.open(page, '/admin/orders', 5000);
  const choose = async (field, from, to) => {
    await page.getByRole('button', { name: `${field} ${from}` }).first().click(); await page.waitForTimeout(700);
    await page.getByRole('menuitem', { name: to, exact: true }).first().click(); await page.waitForTimeout(2200);
  };
  await choose('Payment status', 'Pending', 'Paid');
  await choose('Fulfilment status', 'Processing', 'Shipped');
  await choose('Fulfilment status', 'Shipped', 'Delivered');
  const o = (await L.fsList('orders')).find(x => x.number === order.number);
  L.check(o.paymentStatus === 'Paid' && o.fulfilmentStatus === 'Delivered' && o.trackingNumber, 'admin: Paid → Processing → Shipped → Delivered', `${o.paymentStatus}/${o.fulfilmentStatus}/${o.trackingNumber}`);
  const notes = (await L.fsList('notifications')).filter(n => n.recipient === 'learner@mtalchemy.demo');
  L.check(notes.length >= 3, `customer notified of status changes (${notes.length})`);
  await browser.close();

  ({ browser, page } = await L.start(1280, 900));
  await L.signIn(page, 'learner@mtalchemy.demo', 'AlchemyLearner!26');
  await L.open(page, '/orders', 4000);
  await L.expectText(page, 'Delivered', 'learner sees Delivered in My Orders');
  await L.click(page, 'Notifications', 'button', { wait: 1200 });
  await L.expectText(page, 'Order Delivered', 'notification bell lists update');
  await L.shot(page, 'notifications');
  await browser.close();
  console.log('FAILURES', L.failures());
})();
