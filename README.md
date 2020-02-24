# Terraform infer move tool

[![CI](https://github.com/bigwheel/tfinfermv/workflows/CI/badge.svg)](https://github.com/bigwheel/tfinfermv/actions?query=workflow%3ACI)

## What's this ?

An script that infers terraform resource move and generates 'terraform state mv ...' commands.

## Installation

Put `generate_state_mv.sh` and `infermv` files into your $PATH directory.

## How to use

1. Go your Terraform root module
1. Change your configuration files
1. Run `generate_state_mv.sh {{similarity_threshold - default 1.0}}`

### Similarity Threshold

How many property values need for same resource determination.

If you change only one name of single resource, property values does not changed.
Then you don't have to change Similarity Threshold from 1.0.
However, if you change both resource property values and name,
resource Similarity must go down under 1.0.

For example, a resource has 8 properties and 2 properties changed,
Similarity is (8 - 2) / 8 = 0.75.
Therefore no outputs for the resource when similarity_threshould is greater than 0.75.

You can specify any value as similarity_threshold, but I suggest use 0.7 ~ 1.0 value.
If you need the value lower than 0.7, you should separate resource move commit and
resource property change commit.

## How to run test

```bash
cd test
find .. -not -path '*/tmp*' -a -not -path '*/\.*' | entr ./test.bats
```
