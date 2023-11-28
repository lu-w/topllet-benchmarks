#!/usr/bin/env python
# USAGE: create_abox.py T N S, where T is the time point (in 0,1,2), N a scaling factor >= 1, and S an optional seed

import sys
import random

ONTOLOGY_HEADER = """Prefix(:=<http://mtcq/eval/data#>)
Prefix(owl:=<http://www.w3.org/2002/07/owl#>)
Prefix(rdf:=<http://www.w3.org/1999/02/22-rdf-syntax-ns#>)
Prefix(xml:=<http://www.w3.org/XML/1998/namespace>)
Prefix(xsd:=<http://www.w3.org/2001/XMLSchema#>)
Prefix(rdfs:=<http://www.w3.org/2000/01/rdf-schema#>)

Ontology(<http://mtcq/eval/data>
Import(<http://mtcq/eval>)

Declaration(NamedIndividual(:c))
Declaration(NamedIndividual(:r0))
Declaration(NamedIndividual(:r1))
Declaration(NamedIndividual(:r2))
Declaration(NamedIndividual(:s))

ObjectPropertyAssertion(<http://mtcq/eval#connects> :c :r0)
ObjectPropertyAssertion(<http://mtcq/eval#connects> :c :r1)
ObjectPropertyAssertion(<http://mtcq/eval#connects> :c :r2)

ClassAssertion(<http://mtcq/eval#Road> :r0)
ObjectPropertyAssertion(<http://mtcq/eval#orthogonal> :r0 :r1)

ClassAssertion(<http://mtcq/eval#Road> :r1)
ObjectPropertyAssertion(<http://mtcq/eval#orthogonal> :r1 :r0)

ClassAssertion(<http://mtcq/eval#Road> :r2)

ClassAssertion(<http://mtcq/eval#System> :s)
"""

TWO_WHEELER_DECLARATION = """Declaration(NamedIndividual(:t))
ClassAssertion(<http://mtcq/eval#TwoWheeledVehicle> :t)"""

ONTOLOGY_FOOTER = """DifferentIndividuals(:r0 :r1 :r2)
)
"""

SYSTEM_T0 = "ObjectPropertyAssertion(<http://mtcq/eval#intersects> :s :r0)"
SYSTEM_T1 = "ObjectPropertyAssertion(<http://mtcq/eval#intersects> :s :c)"
SYSTEM_T2 = "ObjectPropertyAssertion(<http://mtcq/eval#intersects> :s :r1)"

TWO_WHEELER_T0 = """ObjectPropertyAssertion(<http://mtcq/eval#parallel> :s :t)
ObjectPropertyAssertion(<http://mtcq/eval#toTheLeftOf> :s :t)
ObjectPropertyAssertion(<http://mtcq/eval#intersects> :t :r0)"""
GOOD_TWO_WHEELER_T1 = "ObjectPropertyAssertion(<http://mtcq/eval#intersects> :t :c)"
BAD_TWO_WHEELER_T1 = "ObjectPropertyAssertion(<http://mtcq/eval#intersects> :t :r0)"
BAD_TWO_WHEELER_T2 = "ObjectPropertyAssertion(<http://mtcq/eval#intersects> :t :r0)"

PROB_GOOD_TWO_WHEELER = 0.9
DEFAULT_SEED = 0


# n scales the number of two-wheelers. for n = 1, there is exactly one good wo-wheeler.
# we randomly add either a good or a bad two-wheeler
def create(t: int, n: int, s: int = DEFAULT_SEED):
    assert t in {0, 1, 2}
    assert n >= 1
    random.seed(s)
    num_of_good_two_wheelers = 1
    for i in range(n - 1):
        if random.random() <= PROB_GOOD_TWO_WHEELER:
            num_of_good_two_wheelers += 1
    num_of_bad_two_wheelers = n - num_of_good_two_wheelers
    print("# MTCQ Evaluation for t = " + str(t) + " and n = " + str(n) + " (seed = " + str(s) + ")")
    print("# With " + str(num_of_good_two_wheelers) + " good two-wheelers and " + str(num_of_bad_two_wheelers) +
          " bad two-wheelers\n")
    print(ONTOLOGY_HEADER)
    if t == 0:
        print(SYSTEM_T0 + "\n")
        for i in range(num_of_good_two_wheelers):
            print(TWO_WHEELER_DECLARATION.replace(":t", ":tg" + str(i)) + "\n")
            print(TWO_WHEELER_T0.replace(":t", ":tg" + str(i)) + "\n")
        for i in range(num_of_bad_two_wheelers):
            print(TWO_WHEELER_DECLARATION.replace(":t", ":tb" + str(i)) + "\n")
            print(TWO_WHEELER_T0.replace(":t", ":tb" + str(i)) + "\n")
    elif t == 1:
        print(SYSTEM_T1 + "\n")
        for i in range(num_of_good_two_wheelers):
            print(TWO_WHEELER_DECLARATION.replace(":t", ":tg" + str(i)) + "\n")
            print(GOOD_TWO_WHEELER_T1.replace(":t", ":tg" + str(i)) + "\n")
        for i in range(num_of_bad_two_wheelers):
            print(TWO_WHEELER_DECLARATION.replace(":t", ":tb" + str(i)) + "\n")
            print(BAD_TWO_WHEELER_T1.replace(":t", ":tb" + str(i)) + "\n")
    elif t == 2:
        print(SYSTEM_T2 + "\n")
        for i in range(num_of_good_two_wheelers):
            print(TWO_WHEELER_DECLARATION.replace(":t", ":tg" + str(i)) + "\n")
        for i in range(num_of_bad_two_wheelers):
            print(TWO_WHEELER_DECLARATION.replace(":t", ":tb" + str(i)) + "\n")
            print(BAD_TWO_WHEELER_T2.replace(":t", ":tb" + str(i)) + "\n")
    print(ONTOLOGY_FOOTER)


if __name__ == "__main__":
    seed = sys.argv[3] if len(sys.argv) > 3 else DEFAULT_SEED
    create(int(sys.argv[1]), int(sys.argv[2]))

