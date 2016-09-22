PYTHON=python3

.NOTPARALLEL:

.PHONY: all
all: test

.PHONY=clean
clean:
	rm -fr build dist *.egg-info .tox MANIFEST .cache
	rm -f *.so
	rm -rf docs/build
	find ./ -name '*.py[co]' -exec rm -f {} \;
	find ./ -depth -name __pycache__ -exec rm -rf {} \;

.PHONY=test
test:
	rm -f pyjose.c
	$(MAKE) egg_info
	tox

.PHONY=version
version:
	rm -f pyjose.c
	$(MAKE) egg_info
	$(PYTHON) setup.py build_ext --inplace
	$(PYTHON) -c 'import pyjose, pprint; pprint.pprint(vars(pyjose))' | grep VERSION

.PHONY=egg_info
egg_info:
	$(PYTHON) setup.py egg_info

.PHONY=release
release: clean egg_info
	$(PYTHON) setup.py packages
