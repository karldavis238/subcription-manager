Overview

The Subscription Manager allows users to create and renew subscriptions that expire after a specified number of blocks.
It is designed to support decentralized applications that require time-limited access control, such as premium content, services, or DAO memberships.

Features

Create and renew subscriptions

Block-height–based subscription expiration

Per-user subscription tracking

Read-only functions to check subscription status

Minimal, auditable, and extensible design

Contract Architecture
Data Structures

subscriptions – maps user principals to subscription expiration blocks

Block height is used as the time reference for subscription validity

Public Functions
Function	Description
subscribe	Create or renew a subscription
is-subscribed	Check if a user’s subscription is active
get-expiration	Retrieve a user’s subscription expiration block
Example Usage
Create or Renew a Subscription
(contract-call? .subscription-manager subscribe u100)

Check Subscription Status
(contract-call? .subscription-manager is-subscribed tx-sender)

Get Subscription Expiration
(contract-call? .subscription-manager get-expiration tx-sender)

Project Structure

subscription-manager.clar    Clarity smart contract
README.md                    Project documentation
tests/                       (Optional) Clarinet test files

Testing

Recommended test cases:

New subscription creation

Subscription renewal before expiration

Subscription expiration after block height

Subscription status queries

Run tests with Clarinet:

clarinet test

Access Control

Any principal can subscribe

Each subscription is tied to a single user address

Subscription validity is determined solely by block height

License

This project is licensed under the MIT License, allowing free use, modification, and distribution.

Contributing

Contributions are welcome.
Please submit issues or pull requests for improvements, bug fixes, or feature enhancements.
