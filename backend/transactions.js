const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('./db'); // <- path to db.js
const authenticateUser = require('./authenticate');
const router = express.Router();

// Create a new transaction
router.post('/', authenticateUser, async (req, res) => {
    const { title, amount, date, category, is_expense } = req.body;
    const user_id = req.user.uid;
  
    if (!title || amount == null || !date || !category) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
  
    try {
      const id = uuidv4();
      await db.query(`
        INSERT INTO transactions (id, user_id, title, amount, date, category, is_expense)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
      `, [id, user_id, title, amount, date, category, is_expense]);
  
      res.status(201).json({ message: 'Transaction created', transaction_id: id });
    } catch (err) {
      console.error('Create failed:', err);
      res.status(500).json({ error: 'Failed to create transaction' });
    }
  });

// Get all transactions for a user
router.get('/', authenticateUser, async (req, res) => {
    const user_id = req.user.uid;
    const { start_date, end_date, category, is_expense } = req.query;

    try {
        let query = `SELECT * FROM transactions WHERE user_id = $1`;
        const params = [user_id];
        let idx = 2;

        if (start_date) {
            query += ` AND date >= $${idx}`;
            params.push(start_date);
            idx++;
        }

        if (end_date) {
            query += ` AND date <= $${idx}`;
            params.push(end_date);
            idx++;
        }
        if (category) {
            query += ` AND category = $${idx}`;
            params.push(category);
            idx++;
        }
        if (is_expense !== undefined) {
            query += ` AND is_expense = $${idx}`;
            params.push(is_expense === 'true');
        }
        query += ` ORDER BY date DESC`;
        
        const {rows} = await db.query(query, params);
        res.status(200).json(rows);
    } catch (err) {
      console.error('Fetch failed:', err);
      res.status(500).json({ error: 'Failed to fetch transactions' });
    }
  });

// Update a transaction
router.put('/:id', authenticateUser, async (req, res) => {
    const user_id = req.user.uid;
    const transaction_id = req.params.id;
    const { title, amount, date, category, is_expense } = req.body;

    if (!title || amount == null || !date || !category) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    try {
        const {rowCount} = await db.query(`
            UPDATE transactions 
            SET title = $1, amount = $2, date = $3, category = $4, is_expense = $5
            WHERE id = $6 AND user_id = $7
        `, [title, amount, date, category, is_expense, transaction_id, user_id]);

        if (rowCount === 0) {
            return res.status(404).json({ error: 'Transaction not found' });
        }

        res.status(200).json({ message: 'Transaction updated successfully' });
    } catch (err) {
      console.error('Update failed:', err);
      res.status(500).json({ error: 'Failed to update transaction' });
    }
  }
);

// Delete a transaction
router.delete('/:id', authenticateUser, async (req, res) => {
    const user_id = req.user.uid;
    const transaction_id = req.params.id;

    try {
        const {rowCount} = await db.query(`
            DELETE FROM transactions 
            WHERE id = $1 AND user_id = $2
        `, [transaction_id, user_id]);

        if (rowCount === 0) {
            return res.status(404).json({ error: 'Transaction not found' });
        }

        res.status(200).json({ message: 'Transaction deleted successfully' });
    } catch (err) {
      console.error('Delete failed:', err);
      res.status(500).json({ error: 'Failed to delete transaction' });
    }
  });

// Get summary of transactions
router.get('/summary', authenticateUser, async (req, res) => {
    const user_id = req.user.uid;
    const { start_date, end_date } = req.query;

    try {
        let query = `
            SELECT 
                SUM(CASE WHEN is_expense THEN amount ELSE 0 END) AS total_expenses,
                SUM(CASE WHEN NOT is_expense THEN amount ELSE 0 END) AS total_income
            FROM transactions 
            WHERE user_id = $1
        `;
        const params = [user_id];
        let idx = 2;

        if (start_date) {
            query += ` AND date >= $${idx}`;
            params.push(start_date);
            idx++;
        }

        if (end_date) {
            query += ` AND date <= $${idx}`;
            params.push(end_date);
        }

        const {rows} = await db.query(query, params);
        res.status(200).json(rows[0]);
    } catch (err) {
      console.error('Summary fetch failed:', err);
      res.status(500).json({ error: 'Failed to fetch transaction summary' });
    }
  });
module.exports = router;