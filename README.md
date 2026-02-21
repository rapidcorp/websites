# Websites

Static multi-project websites bundle served from nginx on `project.zeye.app`.

## Projects

- `landing` -> `/`
- `mla` -> `/mla/`
- `web-weaver` -> `/web-weaver/`
- `BVR_SUPERMARKET` -> `/bvr-supermarket/`

## Operations

Use the project control script:

```bash
./server.sh rebuild   # build static assets
./server.sh start     # install nginx site + reload
./server.sh status    # listener/domain checks
./server.sh stop      # disable nginx site
```

## Runtime

- Local nginx static site listens on port `2005` (`projects.conf`)
- Public domain is `https://project.zeye.app`

## Validation

Run:

```bash
./scripts/verify_websites_setup.sh
```

It checks:
- required static build outputs exist
- nginx site files/symlink exist
- nginx has active listener on `2005`
- local domain probes return HTTP status
