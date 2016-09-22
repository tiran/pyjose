PYTHON=python3

.NOTPARALLEL:

.PHONY: all
all: test

README: README.md
	echo -e '.. WARNING: AUTO-GENERATED FILE. DO NOT EDIT.\n' > $@
	pandoc --from=markdown --to=rst $< >> $@

.PHONY=clean
clean:
	rm -f jose.c jose*.s[ol] jose*.dyn
	rm -fr build dist
	rm -rf docs/build
	find ./ -name '*.py[co]' -exec rm -f {} \;
	find ./ -depth -name __pycache__ -exec rm -rf {} \;

.PHONY=distclean
distclean: clean
	rm -fr *.egg-info .tox MANIFEST .cache
	rm -rf docs/build

.PHONY=test
test: clean
	$(MAKE) egg_info
	tox

.PHONY=egg_info
egg_info:
	$(PYTHON) setup.py egg_info

.PHONY=packages
packages: clean README egg_info
	$(PYTHON) setup.py packages

