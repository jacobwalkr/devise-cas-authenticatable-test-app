# devise-cas-authenticatable-app

This app is purely for testing [devise_cas_authenticatable](https://github.com/nbudin/devise_cas_authenticatable) until I figure out a proper gem dev workflow.

## Usage

Clone this app into a directory alongside the devise_cas_authenticatable gem like so:

```
- parent_dir/
  | devise-cas-authenticatable-app
  | devise_cas_authenticatable
```

Run with:

```bash
docker-compose build

# foreground
docker-compose up

# background
docker-compose up -d
docker-compose logs -f
```

## Users

`scripts/entrypoint.sh` seeds the LDAP server with a user called `user`, password `secret`.

## config/master.key

If you need it, I guess:

```
e2991d6ed6a14dc83b3b3b5f6434107a
```
