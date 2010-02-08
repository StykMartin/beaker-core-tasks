# Include global Makefile targets
include /usr/share/rhts/lib/rhts-make.include

# Test metadata file
METADATA=testinfo.desc

# The toplevel namespace within which the test lives.
TOPLEVEL_NAMESPACE=/distribution

# The name of the package under test:
PACKAGE_NAME=kernel

# The path of the test below the package:
RELATIVE_PATH=install

# For organization purposes I have moved this test into the 
#  /distribution/install/default directory. But it test namespace
#  will remain /distribution/install 

# Required variables
export TESTVERSION=1.9
export TEST=$(TOPLEVEL_NAMESPACE)/$(RELATIVE_PATH)
TEST_DIR=/mnt/tests$(TEST)
BINFILE=hvm_detect

# Built executables should be added here
BUILT_FILES=$(BINFILE).c
FILES=$(BUILT_FILES) $(METADATA) runtest.sh Makefile

build: $(BUILT_FILES)
ifeq ($(shell arch),x86_64)
	@echo "x86_64 arch, hvm_detect will be built"
	gcc $(BINFILE).c -o ./$(BINFILE)
	chmod a+x ./$(BINFILE)
endif
	chmod a+x ./runtest.sh

clean:
	rm -rf ./mnt
	rm -f *~ $(BINFILE)
	rm -f rhts-rh-tests-distribution-install*.noarch.rpm
	rm -f rh-tests-distribution-install*.noarch.rpm

run: build
	./runtest.sh

# Generate the testinfo.desc(METADATA) here:
$(METADATA): Makefile
	@touch $(METADATA)
	@echo "Owner:		Bill Peck <bpeck@redhat.com>" > $(METADATA)
	@echo "Name:		$(TEST)"	>> $(METADATA)
	@echo "Path:		$(TEST_DIR)"	>> $(METADATA)
	@echo "TestVersion:	$(TESTVERSION)"	>> $(METADATA)
	@echo "Description:	Reports back on the Installation that was done" >> $(METADATA)
	@echo "TestTime:	20m"		>> $(METADATA)
	@echo "Priority:	Manual"		>> $(METADATA)
	@echo "Requires:	make"		>> $(METADATA)
	@echo "Requires:	wget"		>> $(METADATA)
	@echo "License:		GPL"		>> $(METADATA)