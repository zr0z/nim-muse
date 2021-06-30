when defined(linux):
  switch("passL", "-ldl -lm -lpthread")
when defined(macosx):
  switch("passL", "-lpthread -lm")


