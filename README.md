This is a quick way to set up an Arch Linux Pacman repository, hosted on Amazon
S3 or an equivalent service.  It can also be easily modified to use SSH/SCP to
upload files to a more traditional web server, or a local machine.

It allows you to run your own repository, so that you can use `pacman` to
install your own packages, and have them easily upgraded when you publish
updates.

### Use ###

1. Create one subdirectory for each repo you wish to establish.
2. Inside this folder, create another one for each architecture you wish to
   support, e.g. `i686`, `x86_64`, `any`, etc.
3. Copy `Makefile.config.sample` to `Makefile.config` and update as required.
4. Build your packages as normal, and put the output `.xz` files into the
   relevant repo's architecture folder from step 2.
5. Run `make` to construct the repo's database and upload it.
6. As packages are updated, copy them in as per steps 4 and 5.  You can delete
   the old `.xz` files if you wish, or leave them around for a while in case
   anyone is looking for older versions if they need to downgrade.

### Example ###

If uploading to `s3://example.com/hello/` and the repo defined in
`Makefile.config` is called `myrepo`, then anyone wishing to use the repo will
need to add this to `/etc/pacman.conf`:

    [myrepo]
    SigLevel = Optional TrustAll
    Server = http://example.com/hello/$repo/$arch/

Run `pacman -Sy` to read in the new repo, after which you can install any
packages from it with the usual `pacman -S packagename`.
