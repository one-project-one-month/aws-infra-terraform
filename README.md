# AWS Infra Terraform Monorepo

This repository manages Terraform code for multiple AWS projects. Each project is isolated in its own folder under `projects/` and can include any AWS resources (EKS, S3, EC2, etc.).

## Structure

```
aws-infra-terraform/
├── README.md
├── .gitignore
├── modules/                # (optional) Shared 
├── projects/
│   ├── <project1>/         # Each project in its own folder
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── <project2>/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── .github/
    └── workflows/
        ├── terraform-ci.yml        # CI workflow for Terraform (plan, validate, etc.)
        ├── terraform-cd.yml        # CD workflow for Terraform (apply to production)
        └── set-matrix.yml          # Shared workflow to determine changed projects
```

## Workflow

1. **Create a new branch** from `main`:
   ```sh
   git checkout -b feature/<your-project-name>
   ```
2. **Add your project** under `projects/<your-project-name>/` with your Terraform files.
3. **Open a Pull Request** to merge your branch into `main`.
4. **Deployment is restricted to `main`**: Only code in `main` is deployed (enforced by CI/CD).

## Adding a New Project

- **Use the `projects/example-project` folder as a template.**
  - Copy the entire `projects/example-project` folder to `projects/<your-project-name>`:
    ```sh
    cp -r projects/example-project projects/<your-project-name>
    ```
  - Update the Terraform files (`main.tf`, `variables.tf`, `outputs.tf`, `provider.tf`, `versions.tf`) to fit your new project's requirements.
- Add your Terraform resources as needed.
- Use shared modules from `modules/` if needed.

## CI/CD

- GitHub Actions can be used to automatically plan/apply Terraform changes.
- Only runs on `main` branch to restrict deployment.
- See `.github/workflows/` for details.

---

