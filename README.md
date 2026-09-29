# Terraform Associate: From Theory to Practice

## About This Project

My learning philosophy is simple: I learn best by doing. After passing the Terraform Associate exam, I created this project to turn certification knowledge into hands-on infrastructure experience and develop a deeper understanding through experimentation.

By sharing what I learn, I hope to contribute something useful to the community and help others practice Terraform. Feedback, corrections, and suggestions are always welcome.

The goal is not to present a finished course or claim that every section is final; **it is a transparent record of deliberate, ongoing practice.**

This is an AI-assisted project. I use OpenAI Codex as a collaborative tool to review documentation, identify inconsistencies, discuss alternatives, and help organize the material. I apply my own judgment to the suggestions, make the final decisions, implement the lab solutions, and validate the behavior. AI-generated output is treated as something to review, not as automatically correct.

## Project status

The labs are complete. The larger architecture checkpoints remain ongoing and will continue to evolve.

| Area | Status | Entry point |
| --- | --- | --- |
| Labs 1–16 | Completed | [Practice index](practice/README.md) |
| Lab 0 | Introductory | [Lab 0](practice/lab_00/lab_00.md) |
| Checkpoint 1 | Ongoing | [Checkpoint 1](practice/checkpoint_01/checkpoint_01.md) |
| Checkpoint 2 | Ongoing | [Checkpoint 2](practice/checkpoint_02/checkpoint_02.md) |

## Start here

- [Terraform Study Guide](docs/README.md) — theory organized by topic.
- [Practical Exercises](practice/README.md) — labs and architecture checkpoints.
- [Repository structure](#repository-structure) — where to find each type of content.

## Repository structure

```text
.
├── README.md                    # Project landing page and status
├── docs/                        # Topic-based Terraform study guide
│   ├── README.md
│   ├── 01-iac-concepts.md
│   ├── 02-terraform-basics.md
│   ├── 03-core-workflow.md
│   ├── 04-state.md
│   ├── 05-modules.md
│   ├── 06-configuration.md
│   └── 07-hcp-terraform.md
├── practice/                    # Hands-on labs and checkpoints
│   ├── README.md
│   ├── lab_00/ through lab_16/
│   └── checkpoint_01/ and checkpoint_02/
└── assets/                      # Shared diagrams and images
```

## How to use the repository

For a structured path, read the chapters in `docs/` and then complete the related labs in `practice/`. Each lab has its own objective, concepts, instructions, and Terraform files. The checkpoints combine several concepts into larger infrastructure exercises.

Most labs are independent. Start with Lab 0 for the Terraform CLI workflow, then continue through the numbered labs. Checkpoints are larger and intentionally remain ongoing.

## Working safely

- Review `terraform plan` before applying changes.
- Never commit credentials, private keys, backend configuration, or state files.
- Use the lab-specific instructions for AWS cleanup.
- Treat examples as learning environments and adapt them before using real infrastructure.

## Collaboration and feedback

The project is built with iterative human review and AI-assisted research. Feedback, corrections, and suggestions are welcome through GitHub issues or pull requests.
