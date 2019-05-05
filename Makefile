include Makefile.config

# All arch .db files in $repo
ALL_ARCH_DBS = $(foreach arch,$(ARCHS),$(repo)/$(arch)/$(repo).db.tar.gz)
ALL_REPO_DBS := $(foreach repo,$(REPOS),$(ALL_ARCH_DBS))

# Intermediate files, used for make clean
ALL_ARCH_DBS_INT = $(foreach arch,$(ARCHS),$(repo)/$(arch)/$(repo).db)
ALL_REPO_DBS_INT := $(foreach repo,$(REPOS),$(ALL_ARCH_DBS_INT))

ALL_ARCH_DIRS := $(foreach repo,$(REPOS),$(addprefix $(repo)/,$(ARCHS)))

.PHONY: all clean FORCE

all: upload.timestamp

clean:
	rm -f upload.timestamp
	-$(foreach repo,$(REPOS),$(foreach arch,$(ARCHS),$(MAKE) -C $(repo)/$(arch) -f ../../Makefile.repo.arch -L REPO=$(repo) clean ; ))

FORCE:

define ARCH_template =
$(1)/$(2)/$(1).db.tar.gz: FORCE
	mkdir -p $(1)/$(2) $(1)/any
	$(MAKE) -C $(1)/$(2) -f ../../Makefile.repo.arch -L REPO=$(1)
endef

$(foreach repo,$(REPOS),\
$(foreach arch,$(ARCHS),\
$(eval $(call ARCH_template,$(repo),$(arch)))\
)\
)

upload.timestamp: $(ALL_REPO_DBS)
# Exclude the .db files so they get uploaded after the archives, to avoid
# people syncing and trying to download the updates before they finish
# uploading.
	aws --profile $(AWS_PROFILE) s3 sync --delete --exclude '*.db*' --exclude '*.files*' . $(AWS_S3_DEST)
	aws --profile $(AWS_PROFILE) s3 sync --delete . $(AWS_S3_DEST)
# You could use a command like this to upload via SCP/SSH instead
#	rsync -av --delete --delete-excluded --exclude=Makefile\* --exclude=\*.old . example.com:/srv/web/
	touch upload.timestamp

