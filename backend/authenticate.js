const admin = require('firebase-admin');
const path = require('path');

// Prevent re-initialization in dev hot reload
if (!admin.apps.length) {
  const serviceAccount = require(path.join(__dirname, './firebase-admin-key.json'));

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const authenticateUser = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized: No token provided' });
  }

  const idToken = authHeader.split('Bearer ')[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Error verifying token:', error);
    return res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
};

module.exports = authenticateUser;
