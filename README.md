# iOS-Finance-Manager

A lightweight personal finance iOS app with backend integration and a home screen widget.

## Features
- Firebase Auth-based sign in / sign up
- Add, edit, delete transactions
- Income vs Expense filtering and category analysis
- Balance auto-calculated from synced backend data
- iOS Widget showing balance, income, and expenses
- Secure token storage via Keychain

## Tech Stack
- SwiftUI + WidgetKit
- Node.js + Express backend
- Firebase Authentication
- PostgreSQL + REST API

## Note for testing with postman
1. Sign up and then Sign in. Save the token
2. For every other API calls (list, add, update, delete), add an "Authorization" field in header with key "Bearer {token}" with {token} being one got from Signing in
