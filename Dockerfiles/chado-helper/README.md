# Chado Loading Helper

This docker image is to help get a new chado database up and running
quickly.

## Steps

### Create a new database container and user 'chadouser'

```sh
docker run -d --name db postgres
```

Now that you've got a blank database, we'll create a new user
'chadouser' inside that database:

```sh
docker run --rm --link db:chado postgres \
    createuser \
    --host chado \
    --username postgres \
    --createdb \
    --echo \
    --login \
    chadouser
```
And create the `chado` database:

```sh
docker run --rm --link db:chado postgres \
    createdb \
    -h chado \
    -U chadouser
    chado
```

### Load the basic schema

```sh
docker run --rm --link db:chado robsyme/chado-helper make load_schema
docker run --rm --link db:chado robsyme/chado-helper make prepdb
```

### Load the ontologies

This step is interactive so that you can specify which ontologies you
wish to load

```sh
docker run --rm --link db:chado --interactive --tty robsyme/chado-helper make ontologies
```

### Backup the sql

Now is probably a good time to take a snapshot of the database so that
you can get back to a clean slate if needed. You can dump the sql to
the current directory using:

```sh
docker run --rm --link db:chado -v $PWD:/dump postgres \
    pg_dump \
    -h chado \
    -U postgres \
    -f /dump/chado_dump.sql\
    chado
```
