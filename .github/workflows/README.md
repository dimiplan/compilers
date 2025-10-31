# GitHub Actions Workflows

## Docker Build, Test, and Deploy

This workflow automates the building, testing, and deployment of the Judge0 compilers Docker image to GitHub Container Registry (ghcr.io).

### Workflow: `docker-build-test-deploy.yml`

#### Triggers
- **Push to main/master branch**: Builds, tests, and deploys the image
- **Pull requests**: Builds and tests only (no deployment)
- **Tags (v*)**: Builds, tests, and creates versioned releases
- **Manual dispatch**: Can be triggered manually from GitHub Actions UI

#### Jobs

1. **Validate** (2-3 minutes)
   - Validates Dockerfile syntax using hadolint
   - Checks all test configuration files (lang.properties)
   - Verifies test runner script syntax
   - Validates version consistency between Dockerfile and tests

2. **Build** (4-8 hours)
   - Builds the complete Docker image with all compilers
   - Uses Docker Buildx for efficient caching
   - Saves the built image as an artifact for testing
   - Uses GitHub Actions cache to speed up subsequent builds

3. **Test** (30-60 minutes)
   - Matrix strategy: Tests each language independently in parallel
   - Tests 34 different programming languages/compilers
   - Uses the built Docker image from the previous step
   - Fails fast disabled to test all languages even if one fails

4. **Test All** (1-2 hours)
   - Runs comprehensive test suite for all languages
   - Ensures full integration testing
   - Runs in parallel with individual language tests

5. **Deploy** (10-15 minutes)
   - Only runs on main/master branch or tags (not on PRs)
   - Pushes image to GitHub Container Registry (ghcr.io)
   - Creates multiple tags:
     - `latest` (for main branch)
     - Version tags (for git tags like v1.0.0)
     - SHA-based tags
     - Branch-based tags

#### Required Permissions

The workflow uses `GITHUB_TOKEN` which is automatically provided by GitHub Actions. To enable pushing to GitHub Container Registry, ensure the following:

1. **Package write permissions** are enabled for the workflow:
   - Go to repository Settings → Actions → General
   - Under "Workflow permissions", select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"
   
2. **Make the package public** (optional, for public access):
   - After the first successful build, go to your repository packages
   - Find the container package
   - Go to Package settings
   - Change visibility to Public if desired

#### Usage

##### Automatic Trigger
The workflow runs automatically when:
- You push commits to main/master
- You create a pull request
- You push a version tag (e.g., `git tag v1.4.0 && git push --tags`)

##### Manual Trigger
1. Go to the Actions tab in your GitHub repository
2. Select "Build, Test, and Deploy Docker Image"
3. Click "Run workflow"
4. Choose the branch and click "Run workflow"

#### Monitoring

- View workflow runs in the Actions tab
- Each job shows detailed logs
- Test results are displayed for each language
- Deployment summary shows all pushed tags

#### Performance Optimization

The workflow uses several optimization strategies:
- **Docker Buildx** with layer caching
- **GitHub Actions cache** for Docker layers
- **Parallel testing** using matrix strategy
- **Artifact sharing** between build and test jobs

#### Estimated Times

| Job | Duration |
|-----|----------|
| Validate | 2-3 minutes |
| Build | 4-8 hours (first build), 1-3 hours (cached) |
| Test (each language) | 2-5 minutes |
| Test All | 1-2 hours |
| Deploy | 10-15 minutes |

**Total workflow time:** 
- First run: ~6-10 hours
- Cached runs: ~2-4 hours
- PR validation: ~4-8 hours (no deploy)

#### Troubleshooting

**Build fails at download step:**
- Check if source URLs are accessible
- Verify version numbers exist upstream
- Review Dockerfile for syntax errors

**Tests fail:**
- Check test logs for specific language failures
- Verify test configurations in `tests/*/lang.properties`
- Ensure source files exist for all tests

**Deploy fails:**
- Verify workflow has write permissions (Settings → Actions → General)
- Check if GITHUB_TOKEN has package write access
- Ensure the repository visibility settings allow package publishing

#### Customization

To modify the workflow:

1. **Change trigger branches:**
   ```yaml
   branches:
     - main
     - develop  # Add more branches
   ```

2. **Adjust timeout:**
   ```yaml
   timeout-minutes: 480  # Increase if builds take longer
   ```

3. **Test specific languages only:**
   Edit the matrix in the `test` job to include only desired languages

4. **Change Docker registry:**
   Update the `REGISTRY` and `IMAGE_NAME` environment variables at the top of the workflow

#### Accessing the Published Image

After successful deployment, the Docker image will be available at:

```bash
# Pull the latest image
docker pull ghcr.io/<owner>/<repo>:latest

# Pull a specific version
docker pull ghcr.io/<owner>/<repo>:v1.4.0

# Pull by SHA
docker pull ghcr.io/<owner>/<repo>:sha-abc123
```

Replace `<owner>` with the repository owner and `<repo>` with the repository name (e.g., `ghcr.io/dimiplan/compilers:latest`).
