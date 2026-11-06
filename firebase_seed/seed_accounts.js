// Demo accounts and employer seat purchases shared by seed.js and seed_rest.js.
const data = require('./seed_data.json');

const accounts = [
  { email: 'admin@mtalchemy.demo', password: 'AlchemyAdmin!26', role: 'Admin', displayName: 'MT Alchemy Admin' },
  { email: 'trainer@mtalchemy.demo', password: 'AlchemyTrainer!26', role: 'Trainer', displayName: 'Mabel Tan' },
  { email: 'employer@mtalchemy.demo', password: 'AlchemyEmployer!26', role: 'Employer', displayName: 'ABC Sdn Bhd',
    extra: { accountType: 'Organization', organizationName: 'ABC Sdn Bhd', registrationNumber: '201901012345', employeeCount: '120', contactPerson: 'Nur Aina', industry: 'Professional services', country: 'Malaysia', phone: '+60 3 1234 5678' } },
  { email: 'learner@mtalchemy.demo', password: 'AlchemyLearner!26', role: 'Learner', displayName: 'Aisha Rahman',
    extra: { accountType: 'Individual', country: 'Malaysia', phone: '+60 12 345 6789', dateOfBirth: '1996-04-12', learningAreas: 'Emotional Intelligence, Leadership' } },
  { email: 'alicia@example.com', password: 'AlchemyLearner!26', role: 'Learner', displayName: 'Alicia Wong' },
  { email: 'daniel@example.com', password: 'AlchemyLearner!26', role: 'Learner', displayName: 'Daniel Lee' },
  { email: 'farah@example.com', password: 'AlchemyLearner!26', role: 'Learner', displayName: 'Farah Nordin' },
];

/// Paid seat purchases so the employer's starter assignments are covered.
function employerSeatOrders() {
  return [['ei-fundamentals', 10, 'MA1000000000001'], ['leadership', 5, 'MA1000000000002']].map(([id, seats, number]) => {
    const c = data.courses[id];
    return {
      number,
      date: '2026-09-01T09:00:00.000',
      lines: [{
        product: { id: `course:${id}`, name: c.title, description: `Online course: ${c.title}`, price: c.price, category: 'Course', icon: 0, imagePath: null, imageBytes: null, downloadAssetPath: null, digital: true, stock: 0, published: true, position: 0 },
        quantity: seats,
      }],
      total: c.price * seats,
      paymentStatus: 'Paid',
      paymentMethod: 'Bank transfer · PAY-SEED',
      fulfilmentStatus: 'Available',
      customerName: 'ABC Sdn Bhd',
      customerEmail: 'employer@mtalchemy.demo',
      customerPhone: '+60 3 1234 5678',
      billingAddress: 'Kuala Lumpur, Malaysia',
      shippingAddress: null,
      trackingNumber: null,
      stockReserved: false,
    };
  });
}

module.exports = { accounts, employerSeatOrders };
