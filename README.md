<div align="center">

# Salva Naming Service (SNS v2.1.1)

### Decentralized Identity Infrastructure for Wallets, Payments & Financial Applications

*Protocol-owned namespaces, sovereign per-namespace registries, human-readable on-chain identities.*

<br/>

[![Network](https://img.shields.io/badge/Network-Base_Mainnet_%26_Testnet-0052FF?style=for-the-badge&logo=coinbase)](https://base.org)
[![Language](https://img.shields.io/badge/Stack-Solidity_|_Yul_Assembly-363636?style=for-the-badge&logo=ethereum)](https://soliditylang.org)
[![License](https://img.shields.io/badge/License-MIT-D4AF37?style=for-the-badge)](./LICENSE)
[![Status](https://img.shields.io/badge/Status-Live_on_Base-00C853?style=for-the-badge)](https://basescan.org)

> **SNS is live — exclusively on Base.** A decentralized identity layer enabling wallets, exchanges and financial applications to issue trusted human-readable blockchain identities.

</div>

---

## Deployments

| Network | Singleton (ERC-1967 Proxy) |
|---|---|
| Base Mainnet | `0x` |
| Base Sepolia (Testnet) | `0xC9Eaa3DD7c87bE3269677F281C59A063201D4e09` |

---

## SNS V2.1.1 Differentiator

### Protocol-Owned, Ownership-Aware Namespaces

Every namespace is deployed as its own registry contract, and that registry decides who's allowed to write to it — via a single property: how many owners it has.

**Public namespaces** — like `@ngns, @sant` — belong to shared infrastructure or a protocol rather than a single person. They have no owners, so anyone can link into them. Because anyone can write, an alias here only means something if it names the person who put it there:

```
pay.bob@ngns                            ✅ clear — bob's payment alias
pay.alice@sant                          ✅ clear — alice's payment alias
pay@sant                                ✅ valid, but no owner reference, hard to knows who owns it
```

**Private namespaces** — like `@cboi`, `@chainlink` — already *are* an identity. Only the addresses registered as owners of that namespace may link or unlink inside it. Because the namespace itself already names its owner, aliases don't need a human-name prefix:

```
pay@cboi                                ✅ clear — cboi's own namespace, cboi's own alias
pay.usdc.base@cboi                      ✅ clear — cboi's own alias, with more reference
send.usdc@chainlink                     ✅ clear — chainlink's own namespace
eth.usdc.aggregatorv3.base@chainlink    ✅ clear — chainlink's own namespace, with more reference
```

### Registry Isolation

Each namespace's records live in that namespace's own registry contract — never in shared storage. One namespace can't collide with, overwrite, or leak into another.

### Guardian-Protected Namespace Ownership

New namespaces are only created through MultiSig governance. No organization can spin up or impersonate another protocol's namespace unilaterally.

### Flexible Resolution

A linked record isn't limited to a wallet address — Most integrations resolve it straight to an address, but the same infrastructure can carry other data too.

---

## Architecture

SNS routes every namespace through a single Singleton contract, but the actual alias data lives inside that namespace's own registry.

```
                      MultiSig Governance
                              │
                       initializeRegistry
                              │
                              ▼
                ┌───────────────────────────┐
                │     Singleton (Router)     │
                │  nsKey (bytes4) → registry │
                └─────────────┬──────────────┘
                              │  link / unlink / resolve
                              │  (nameHash, nsKey, data)
               ┌──────────────┼──────────────┐
               ▼                             ▼
   Registry Clone (@ngns)         Registry Clone (@cboi)
     public — anyone may link        private — only owner(s) may link
     _records[node] → data           _records[node] → data
```

### Resolution Pipeline

Handles are parsed off-chain before touching the chain:

1. **Full handle:** `pay.alice@salva`
2. **Off-chain split:** name = `pay.alice`, namespace = `@salva`
3. **Off-chain hashing:**
   - `nameHash = keccak256("pay.alice")` → `bytes32`
   - `nsKey = bytes4(keccak256("@salva"))` → `bytes4`
4. **On-chain lookup:** `Singleton.resolve(nameHash, nsKey)`
   - Singleton finds the `@salva` registry from `nsKey`
   - Singleton derives the record's storage key from `(nameHash, nsKey)`
   - The registry returns the stored record
5. **Result:** the linked value — cast to an address via `resolveAddr()` when it represents a wallet.

One lookup. One registry read. Deterministic resolution.

---

## Use Cases

- Human-readable crypto payments
- Wallet identity, personal and organizational
- Exchange usernames under a shared public namespace
- Enterprise blockchain identity with owner-restricted namespaces
- Stablecoin recipient aliases
- Cross-application identity resolution
- Web3 financial infrastructure

---

## 💻 Developer Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Setup

```bash
git clone https://github.com/salva-Nexus/SNS-V2.1.1
cd SNS-V2.1.1
forge install
forge build
```

### Testing

```bash
# Run all tests
forge test

# Run with verbose trace output
forge test -vvv

# Run a specific test file
forge test --mt test/Singleton.t.sol -vvv
```

---

## ⚖️ License

Distributed under the MIT License. See [`LICENSE`](./LICENSE) for more information.