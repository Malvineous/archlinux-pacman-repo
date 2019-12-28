include Makefile.config

# All arch .db files in $repo
ALL_ARCH_DBS = $(foreach arch,$(ARCHS),public/$(repo)/$(arch)/$(repo).db.tar.gz)
ALL_REPO_DBS := $(foreach repo,$(REPOS),$(ALL_ARCH_DBS))

# Intermediate files, used for make clean
#ALL_ARCH_DBS_INT = $(foreach arch,$(ARCHS),public/$(repo)/$(arch)/$(repo).db)
#ALL_REPO_DBS_INT := $(foreach repo,$(REPOS),$(ALL_ARCH_DBS_INT))

ALL_ARCH_TIMESTAMPS = $(foreach arch,$(ARCHS),public/$(repo)/$(arch)/upload.timestamp)
ALL_REPO_TIMESTAMPS := $(foreach repo,$(REPOS),$(ALL_ARCH_TIMESTAMPS))

ALL_ARCH_DIRS := $(foreach repo,$(REPOS),$(addprefix $(repo)/,$(ARCHS)))

.PHONY: all clean FORCE

#all: upload.timestamp
all: $(ALL_REPO_TIMESTAMPS)

# Delete all the timestamp files so the next run will try to upload everything
# again.  Only needed if you've changed something that doesn't cause the .db to
# get rebuilt.
reset-timestamps:
	rm -f -v $(ALL_REPO_TIMESTAMPS)

clean:
	-$(foreach repo,$(REPOS),$(foreach arch,$(ARCHS),$(MAKE) -C public/$(repo)/$(arch) -f ../../../Makefile.repo.arch -L REPO=$(repo) clean ; ))

FORCE:

define ARCH_template =
public/$(1)/$(2)/$(1).db.tar.gz: FORCE
	mkdir -p public/$(1)/$(2)
	$(MAKE) -C public/$(1)/$(2) -f ../../../Makefile.repo.arch -L REPO=$(1)

public/$(1)/$(2)/upload.timestamp: public/$(1)/$(2)/$(1).db.tar.gz
# Exclude the .db files so they get uploaded after the archives, to avoid
# people syncing and trying to download the updates before they finish
# uploading.
	aws --profile $(AWS_PROFILE) s3 sync $(AWS_S3_PARAMS) --delete --exclude 'upload.timestamp' --exclude '*.db*' --exclude '*.files*' public/$(1)/$(2)/ $(AWS_S3_DEST)$(1)/$(2)/
	aws --profile $(AWS_PROFILE) s3 sync $(AWS_S3_PARAMS) --delete --exclude 'upload.timestamp' public/$(1)/$(2)/ $(AWS_S3_DEST)$(1)/$(2)/
# You could use a command like this to upload via SCP/SSH instead
#	rsync -av --delete --delete-excluded --exclude=Makefile\* --exclude=\*.old . example.com:/srv/web/
	touch public/$(1)/$(2)/upload.timestamp
endef

$(foreach repo,$(REPOS),\
$(foreach arch,$(ARCHS),\
$(eval $(call ARCH_template,$(repo),$(arch)))\
)\
)
