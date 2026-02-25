# nova_inventory

Sistema de inventário do NOVA Framework. Gestão de itens, peso, uso de itens e UI. Integra com o Player Object do nova_core.

## Dependências

- **nova_core** (obrigatório)
- **oxmysql** (persistência, se usada)

## Instalação

1. Coloca a pasta `nova_inventory` em `resources/[nova]/`.
2. No `server.cfg`:

```cfg
ensure nova_core
ensure oxmysql
ensure nova_inventory
```

## Configuração

Em `config.lua` e `locales.lua`: peso máximo, itens, labels e mensagens.

## Exports (server)

- `AddItem`, `RemoveItem`, `HasItem`, `GetItemCount`
- `GetPlayerInventory`, `SetInventoryMaxWeight`
- `OpenInventory`, `CloseInventory`, `IsOpen` (client)

## Estrutura

- `client/main.lua` — UI e interação
- `client/useitems.lua` — lógica de uso de itens
- `server/main.lua` — persistência e validação
- `config.lua`, `locales.lua`
- `html/` — interface

## Documentação

[NOVA Framework Docs](https://github.com/NoVaPTdev) — guia Inventário.

## Licença

Parte do ecossistema NOVA Framework.
