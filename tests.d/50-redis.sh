#!/bin/sh

echo "TESTS: Redis running..."
if ! pgrep redis-server; then
	echo "CHECK FAILED (redis): Not running"
	false
fi

if ! redis-cli ping; then
	echo "CHECK FAILED (redis): Ping failed"
	false
fi

