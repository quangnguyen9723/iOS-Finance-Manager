const express = require('express');
const cors = require('cors');
const dotenv = require("dotenv")
const { v4: uuidv4 } = require('uuid');
const {getFirestore} = require('firebase/firestore')
const firebase = require('firebase/app');
const { 
  getAuth: getClientAuth, 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword, 
  signOut 
} = require('firebase/auth');
const transactionsRouter = require('./transactions');

// Initialize express app
const app = express();
app.use(express.json());
app.use(cors({ origin: true }));
app.use('/transactions', transactionsRouter);

dotenv.config()

// Initialize Firebase Client SDK for authentication
const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID
};

const firebaseApp = firebase.initializeApp(firebaseConfig);
const clientAuth = getClientAuth(firebaseApp);

// Get Firestore instance
const db = getFirestore(firebaseApp);

// Middleware to verify Firebase ID token
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
    console.error('Error verifying auth token:', error);
    return res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
};

// Authentication routes
// Sign Up
app.post('/auth/signup', async (req, res) => {
  const { email, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }
  
  try {
    const userCredential = await createUserWithEmailAndPassword(clientAuth, email, password);
    const user = userCredential.user;
    const token = await user.getIdToken();
    
    return res.status(201).json({ 
      uid: user.uid,
      email: user.email,
      token
    });
  } catch (error) {
    console.error('Error creating user:', error);
    return res.status(400).json({ error: error.message });
  }
});

// Sign In
app.post('/auth/signin', async (req, res) => {
  const { email, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }
  
  try {
    const userCredential = await signInWithEmailAndPassword(clientAuth, email, password);
    const user = userCredential.user;
    const token = await user.getIdToken();
    
    return res.status(200).json({ 
      uid: user.uid,
      email: user.email,
      token
    });
  } catch (error) {
    console.error('Error signing in:', error);
    return res.status(401).json({ error: 'Invalid email or password' });
  }
});

// Sign Out
app.post('/auth/signout', async (req, res) => {
  try {
    await signOut(clientAuth);
    return res.status(200).json({ message: 'Successfully signed out' });
  } catch (error) {
    console.error('Error signing out:', error);
    return res.status(500).json({ error: 'Error signing out' });
  }
});

// Transaction routes
// Add a new transaction
app.post('/transactions', authenticateUser, async (req, res) => {
  const { 'transaction-type': transactionType, category, date, amount } = req.body;
  const userId = req.user.uid;
  
  // Validate required fields
  if (!transactionType || !category || !date || amount === undefined) {
    return res.status(400).json({ error: 'All fields are required: transaction-type, category, date, amount' });
  }
  
  try {
    // Create transaction object
    const transactionId = uuidv4();
    const transaction = {
      'transaction-id': transactionId,
      'transaction-type': transactionType,
      category,
      date,
      amount,
      userId,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    // Add to Firestore
    await db.collection('transactions').doc(transactionId).set(transaction);
    
    return res.status(201).json({ 
      message: 'Transaction created successfully',
      transactionId 
    });
  } catch (error) {
    console.error('Error adding transaction:', error);
    return res.status(500).json({ error: 'Failed to add transaction' });
  }
});

// Get all transactions for a user
app.get('/transactions', authenticateUser, async (req, res) => {
  const userId = req.user.uid;
  
  try {
    const snapshot = await db.collection('transactions')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .get();
    
    const transactions = [];
    snapshot.forEach(doc => {
      transactions.push(doc.data());
    });
    
    return res.status(200).json(transactions);
  } catch (error) {
    console.error('Error fetching transactions:', error);
    return res.status(500).json({ error: 'Failed to fetch transactions' });
  }
});

// Start the server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app; // For testing purposes