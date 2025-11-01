# Docker Build Improvements

## Problem Statement
The original Docker build procedure had an issue: when a build failed partway through installing compilers, the entire build would need to restart from scratch on retry, wasting significant time.

## Solution: Multi-Stage Build with Independent Caching

The Dockerfile has been refactored into a multi-stage build with 33 stages:
- 1 base stage
- 31 compiler/tool stages (gcc-stage, ruby-stage, python-stage, etc.)
- 1 final stage

### How It Works

Each compiler installation is now its own Docker stage:

```dockerfile
FROM base AS gcc-stage
ENV GCC_VERSION=15.2.0
RUN [install GCC]

FROM gcc-stage AS ruby-stage
ENV RUBY_VERSION=3.4.7
RUN [install Ruby]

FROM ruby-stage AS python-stage
ENV PYTHON_VERSION=3.14.0
RUN [install Python]
```

### Benefits

#### 1. **Resilient to Build Failures**

**Before (single-stage with loops):**
```
Build: GCC (20 min) → Ruby (5 min) → Python (10 min) → Rust FAILS
Retry: GCC (20 min) → Ruby (5 min) → Python (10 min) → Rust...
Total time wasted on retry: 35 minutes
```

**After (multi-stage):**
```
Build: GCC stage (20 min, cached) → Ruby stage (5 min, cached) → Python stage (10 min, cached) → Rust stage FAILS
Retry: GCC (0 sec, from cache) → Ruby (0 sec, from cache) → Python (0 sec, from cache) → Rust...
Total time wasted on retry: ~0 minutes
```

#### 2. **Smart Cache Invalidation on Version Updates**

When you update a compiler version, only that stage and subsequent stages are rebuilt.

**Example:** Updating Python from 3.14.0 to 3.15.0

```
Stages 1-2 (GCC, Ruby): CACHED ✓
Stage 3 (Python): REBUILT (version changed)
Stages 4-33 (all after Python): REBUILT (dependencies changed)
```

**Proof of Cache Invalidation:**
```bash
# Build 1: Establish cache
$ docker build -f Dockerfile.test -t test:v1 .
stage1: Built in 2 seconds
stage2: Built in 2 seconds
stage3: Built in 2 seconds

# Build 2: No changes
$ docker build -f Dockerfile.test -t test:v2 .
stage1: CACHED (0 seconds)
stage2: CACHED (0 seconds)
stage3: CACHED (0 seconds)

# Build 3: Change VERSION2 in stage2
$ docker build -f Dockerfile.test -t test:v3 .
stage1: CACHED (0 seconds) ← Earlier stage unaffected
stage2: Built in 2 seconds ← Rebuilt due to version change
stage3: Built in 2 seconds ← Rebuilt due to dependency
```

#### 3. **Better Debugging**

Each stage is isolated, making it easy to identify which compiler installation failed:
- Clear stage names in build output
- Can build up to specific stage: `docker build --target python-stage .`
- Easier to test individual compiler installations

#### 4. **No Loops = Predictable Builds**

Changed from:
```dockerfile
ENV GCC_VERSIONS 15.2.0
RUN for VERSION in $GCC_VERSIONS; do
  # install GCC
done
```

To:
```dockerfile
ENV GCC_VERSION=15.2.0
RUN # install GCC $GCC_VERSION
```

Benefits:
- Simpler, more readable Dockerfile
- Easier to debug failures
- Consistent variable naming (VERSION not VERSIONS)

### Cache Mechanism

The workflow uses GitHub Actions cache:
```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

- **Type**: GitHub Actions cache backend
- **Mode**: `max` - caches all layers, not just final image
- **Scope**: Per branch
- **Retention**: 7 days of inactivity

### Additional Improvements

1. **Consistent ENV format**: All use `KEY=value` (not `KEY value`)
2. **Proper quoting**: Command substitutions like `"$(nproc)"` are quoted
3. **Explicit target**: Workflow specifies `target: final` for clarity

### Testing Locally

```bash
# Build entire image
DOCKER_BUILDKIT=1 docker build -t compilers:test .

# Build up to specific stage (faster for testing)
DOCKER_BUILDKIT=1 docker build --target python-stage -t compilers:python .

# Verify cache behavior
docker build -t test:v1 .        # First build
docker build -t test:v2 .        # Should use cache
# Change a version in Dockerfile
docker build -t test:v3 .        # Only changed stage+ rebuilt
```

### Impact

**Time Savings Example** (hypothetical):
- Full build from scratch: ~4 hours
- Build failure at stage 20: Previously 3+ hours wasted on retry
- With multi-stage: Only ~1 hour to rebuild from stage 20 onwards
- **Savings: ~2 hours per build failure**

### Future Enhancements

Possible further optimizations:
1. Add cache mounts for `/tmp` downloads: `RUN --mount=type=cache,target=/var/cache/build`
2. Parallel stage builds (requires more complex workflow)
3. Registry-based caching for cross-runner sharing
