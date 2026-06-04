# Mugenlink Network

Multi-chain blockchain analytics platform — real-time data, intelligence, and compliance tools for 11+ chains.

**Phase 1** — Live pipeline across Bitcoin, Ethereum Classic, Dogecoin, Litecoin, Dash, Zcash, eCash, Cardano, Monero, Liquid Network, Bitcoin Cash.

## Repositories

| Repo | Purpose |
|------|---------|
| [pipeline](https://github.com/Mugenlink-Network/pipeline) | Blockchain data pipeline — ingests Blockchair/3xpl → S3 → Snowflake → dbt marts |
| [api](https://github.com/Mugenlink-Network/api) | FastAPI backend + Kafka ingestor serving the console and public data endpoints |
| [console](https://github.com/Mugenlink-Network/console) | Next.js frontend — product dashboard + public blockchain explorer profiles |
| [sdk](https://github.com/Mugenlink-Network/sdk) | Shared Python libraries + TypeScript UI kit, published to Harbor |
| [infra](https://github.com/Mugenlink-Network/infra) | Terraform IaC (AWS + Snowflake + Doppler), Helm charts, k3s/Cilium, observability |
| [gitops](https://github.com/Mugenlink-Network/gitops) | ArgoCD ApplicationSets — source of truth for production |

## Stack

`Python` `FastAPI` `Next.js` `dbt` `Snowflake` `Kafka` `k3s` `Cilium` `ArgoCD` `Terraform` `Doppler`
