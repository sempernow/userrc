# [`sempernow/home`](https://github.com/sempernow/home "GitHub.com") 

A portable Bash shell configuration that adapts to its environment 
and configures many aliases, completion scripts, and user-defined functions,
including those for `git`, `docker`, `kubectl` and `helm`.

Tested on:

- Linux
    - `bash`
    - `sh`
- WSL(2)
- Windows Git bash
- Cygwin

## Get

```bash
git clone https://github.com/sempernow/home.git
cd home
```

## Install

For `$USER`

```bash
make user
```

For all users (don't)

```bash
make all
```
- Use only on your own host.

If the environment lacks `make`, 
then run directly: [`make.recipes.sh`](make.recipes.sh):

```bash
# For $USER
./make.recipes.sh user

# For all users
./make.reciptes.sh all
```

## Demo 

```bash
# Regular user
bash
# Login shell
bash --login
# Root user
sudo su --login
```

## Demo at `bash` and `sh` Environments

### `sh` @ busybox (or alpine)

```bash
app=bbox
docker run --rm -d --name $app -v $(pwd):/root -w /root busybox sleep 1d
``` 

```bash
docker exec -it $app sh
```
```bash
~ # . ./.bashrc
```

### `bash` @ Ubuntu

```bash
app=ubox
docker run --rm -d --name $app -v $(pwd):/root -w /root ubuntu sleep 1d
```

```bash
docker exec -it $app bash
```
- Note this fails at `sh`

Useful:

```bash
# Create a user
adduser u1
# Allow multi-byte Unicode character prompt
export LANG=${LANG:-C.UTF-8}
```

## References:

- [Git completion scripts](https://github.com/git/git/tree/master/contrib/completion "github.com/git")


### &nbsp;

