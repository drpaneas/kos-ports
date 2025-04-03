# kos-ports ##version##
#
# scripts/version.mk
# Copyright (C) 2015 Lawrence Sebald
#

# Update target that handles both git and version-based ports
update:
	@if [ -f ${KOS_PORTS}/lib/.kos-ports/${PORTNAME} ] ; then \
		if [ -f "${KOS_PORTS}/lib/.kos-ports/${PORTNAME}.hash" ] ; then \
			if [ -n "${GIT_REPOSITORY}" ] ; then \
				last_hash=`cat ${KOS_PORTS}/lib/.kos-ports/${PORTNAME}.hash` ; \
				echo "Checking ${PORTNAME} for updates..." ; \
				echo "  Last stored hash: $$last_hash" ; \
				tmp_dir=`mktemp -d` ; \
				git clone ${GIT_REPOSITORY} $$tmp_dir > /dev/null 2>&1 ; \
				if [ $$? -ne 0 ] ; then \
					echo "  ✗ Failed to clone repository. Please check your network connection." ; \
					rm -rf $$tmp_dir ; \
					exit 1 ; \
				fi ; \
				cd $$tmp_dir ; \
				if [ -n "${GIT_BRANCH}" ] ; then \
					echo "  Checking specified branch: ${GIT_BRANCH}" ; \
					git checkout ${GIT_BRANCH} > /dev/null 2>&1 ; \
				else \
					if git show-ref --verify --quiet refs/heads/main ; then \
						echo "  Using default branch: main" ; \
						git checkout main > /dev/null 2>&1 ; \
					elif git show-ref --verify --quiet refs/heads/master ; then \
						echo "  Using default branch: master" ; \
						git checkout master > /dev/null 2>&1 ; \
					fi ; \
				fi ; \
				current_hash=`git rev-parse HEAD` ; \
				echo "  Current repository hash: $$current_hash" ; \
				cd - > /dev/null ; \
				rm -rf $$tmp_dir ; \
				if [ "$$last_hash" = "$$current_hash" ] ; then \
					echo "  ✓ ${PORTNAME} is up to date with git repository. No changes detected." ; \
					exit 0 ; \
				else \
					echo "  ! ${PORTNAME} has new changes in repository. Rebuilding..." ; \
					cd ${KOS_PORTS} && $(MAKE) -C ${PORTNAME} clean install ; \
				fi ; \
			else \
				echo "Checking ${PORTNAME} for updates..." ; \
				echo "  ✗ ${PORTNAME} has a hash file but no GIT_REPOSITORY defined." ; \
				echo "  This port needs to be migrated to use GIT_REPOSITORY for proper update detection." ; \
				echo "  For now, you can use 'make clean install' to ensure you have the latest version." ; \
				exit 1 ; \
			fi ; \
		else \
			if [ -n "${GIT_REPOSITORY}" ] ; then \
				echo "Checking ${PORTNAME} for updates..." ; \
				echo "  ! ${PORTNAME} is installed but no git hash is stored yet." ; \
				echo "  Performing clean reinstall to ensure latest state..." ; \
				cd ${KOS_PORTS} && $(MAKE) -C ${PORTNAME} clean install ; \
			else \
				echo "Checking ${PORTNAME} for updates..." ; \
				echo "  ✗ ${PORTNAME} is not using the new update mechanism." ; \
				echo "  This port relies on PORTVERSION for updates, which may not always reflect the latest changes." ; \
				echo "  To ensure you have the latest version, please run: make uninstall && make install" ; \
				exit 1 ; \
			fi ; \
		fi ; \
	else \
		echo "Checking ${PORTNAME} for updates..." ; \
		echo "  ✗ ${PORTNAME} is not currently installed." ; \
		echo "  Nothing to update. To install this port, run: make clean install" ; \
		exit 1 ; \
	fi

# Update target that handles both the port and its dependencies
update-with-deps:
	@if [ -n "${DEPENDENCIES}" ] ; then \
		echo "Checking dependencies for ${PORTNAME}..." ; \
		for dep in ${DEPENDENCIES} ; do \
			if [ -f "${KOS_PORTS}/lib/.kos-ports/$$dep" ] ; then \
				echo "  Updating dependency: $$dep" ; \
				cd ${KOS_PORTS}/$$dep && $(MAKE) update ; \
			else \
				echo "  Skipping dependency: $$dep (not installed)" ; \
			fi ; \
		done ; \
		echo "---" ; \
	fi
	@echo "Checking ${PORTNAME} for updates..."
	@$(MAKE) update

# Show dependencies for this port
show-deps:
	@echo "Dependencies for ${PORTNAME}:"
	@for dep in ${DEPENDENCIES} ; do \
		if [ -f "${KOS_PORTS}/lib/.kos-ports/$$dep" ] ; then \
			echo "  ✓ $$dep (installed)" ; \
		else \
			echo "  ✗ $$dep (not installed)" ; \
		fi ; \
	done

# Helper target to print dependencies
print-deps:
	@echo "${DEPENDENCIES}"
