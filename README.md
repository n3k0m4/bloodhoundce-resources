# Compass Security BloodHound CE Resources

![](./banner.jpg)

This repository contains some useful resources regarding BloodHound CE:

- BloodHound CE Custom Queries [↓](#bloodhound-ce-custom-queries)
- BloodHound Operator Custom Queries [↓](#bloodhound-operator-custom-queries)
- Useful Links [↓](#useful-links)

## BloodHound CE Custom Queries

These queries are used in BloodHound CE to analyze your collected data.

### Direct Usage

You can directly copy the [BloodHound CE Custom
Queries](custom_queries/BloodHound_CE_Custom_Queries.md) from your browser into
your BloodHound CE instance.

### Import via GUI (JSON files)

You can generate ready-to-import JSON files and import them through the
BloodHound CE GUI. Only `jq` is required:

```bash
sudo apt -y install jq
```

Generate the JSON files:

```bash
./scripts/convert-to-bloodhound-ce-custom-queries-json.sh
```

The files are written to `custom_queries/json/` and can then be imported from
the BloodHound CE GUI.

### Import via API (bash + curl)

The scripts in `scripts/` talk directly to the BloodHound CE REST API, so no
PowerShell or extra modules are needed — only `bash`, `curl` and `jq`:

```bash
sudo apt -y install curl jq
```

#### Create a Session

Run `create-bloodhound-session.sh` to authenticate against the BloodHound CE
API. It stores a session token in a session file (default:
`$HOME/.bloodhound_ce_session`) that the import script reuses:

```bash
./scripts/create-bloodhound-session.sh -p 'YourP@ssw0rd'
```

Parameters:

- `-p PASSWORD`: Password (mandatory; if you don't specify it on the
  command line, you will be prompted)
- `-u USERNAME`: Username (optional, default: `admin`)
- `-H HOSTNAME`: Hostname / IP address of the BloodHound API (optional,
  default: `127.0.0.1`)
- `-P PORT`: Port of the BloodHound API (optional, default: `8080`)
- `-f FILE`: Session file to write (optional, default:
  `$HOME/.bloodhound_ce_session`, or `$BH_SESSION_FILE` if set)

#### Query Import

Execute `import-bloodhound-ce-custom-queries.sh` to import the custom queries.
It first removes existing queries whose name starts with `[C-`, then imports the
current set:

```bash
./scripts/import-bloodhound-ce-custom-queries.sh
```

The imported queries are then shown in BloodHound:

![Custom Queries](./custom_queries/custom_queries.png)

## BloodHound Operator Custom Queries

These queries are used in a BloodHound Operator session, to modify your
collected data.

### Usage

> **Note:** These queries use the
> [BloodHoundOperator](https://github.com/SadProcessor/BloodHoundOperator)
> cmdlets (`BHNodeGroup`, `BHPath`, `Add-BHNodeToNodeGroup`, …), which are only
> available in PowerShell. On Linux you can install PowerShell
> (`sudo apt -y install powershell`, then start it with `pwsh`) and load the
> module before using these queries.

Load the `BloodHoundOperator` module and create a session:

```powershell
Import-Module ./BloodHoundOperator/BloodHoundOperator.ps1
# Authenticate and create the operator session (see the BloodHoundOperator docs)
```

Then directly copy the [BloodHound Operator Custom Queries](custom_queries/BloodHound_Operator_Custom_Queries.md)
into your PowerShell console.

## Useful Links

### BloodHound

- BloodHound Documentation: https://bloodhound.specterops.io/
  - Nodes: https://bloodhound.specterops.io/resources/nodes/overview
  - Edges: https://bloodhound.specterops.io/resources/edges/overview
  - Release Notes: https://bloodhound.specterops.io/resources/release-notes/summary
- BloodHound GitHub: https://github.com/SpecterOps/BloodHound
- SharpHound GitHub: https://github.com/SpecterOps/SharpHound

### Neo4J Cypher

- Neo4J: Cypher Manual: https://neo4j.com/docs/cypher-manual
- Neo4J: Cypher Cheat Sheet: https://neo4j.com/docs/cypher-cheat-sheet/
- Cypher Queries in BloodHound Enterprise:
  https://posts.specterops.io/cypher-queries-in-bloodhound-enterprise-c7221a0d4bb3
- BloodHound: Searching with Cypher:
  https://support.bloodhoundenterprise.io/hc/en-us/articles/16721164740251-Searching-with-Cypher
- BloodHound Documentation: Supported Cypher Syntax:
  https://bloodhound.specterops.io/analyze-data/cypher-supported
