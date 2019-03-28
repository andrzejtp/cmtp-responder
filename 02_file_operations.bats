#!/usr/bin/env bats
#
# SPDX-License-Identifier: Apache-2.0
#
# (c) Collabora Ltd. 2019
# Author: Andrzej Pietrasiewicz <andrzej.p@collabora.com>
#

setup()
{
	load config
	load mtp-utilities
	load file-utilities
}

store_empty()
{
	local FILES=`mtp_list_files "$STORE_NAME" ""`
	[ x"$FILES" == "x" ] || return 1

	local FOLDERS=`mtp_list_folders "$STORE_NAME" ""`
	[ x"$FOLDERS" == "x" ] || return 1

	return 0
}

add_file_to_store()
{
	local NAME="${1}"
	random_file "$NAME"

	local ORIG_MD5=`md5sum "$NAME" | cut -f1 -d' '`

	run mtp_copy_to_store "$STORE_NAME" / "$NAME"
	[ $status -eq 0 ] || { echo "Copying to store failed"; return 1; }

	run mtp_retrieve_from_store "$STORE_NAME" / "$NAME" r_"$NAME"
	[ $status -eq 0 ] || { echo "Retrieving from store failed"; return 1; }

	local R_MD5=`md5sum r_"$NAME" | cut -f1 -d' '`
	[ "$ORIG_MD5" == "$R_MD5" ] || { echo "md5 mismatch"; return 1; }

	return 0
}

remove_file_from_store()
{
	local NAME="${1}"

	run mtp_remove_from_store "$STORE_NAME" / "$NAME"

	[ $status -eq 0 ] || { echo "Removing from store failed"; return 1; }

	run mtp_retrieve_from_store "$STORE_NAME" / "$NAME" r_"$NAME"
	[ $status -eq 1 ] || { echo "Unexpectedly retrieved file"; return 1; }

	return 0
}

teardown()
{
	rm -rf *.bin
}

@test "Verify empty store" {
	run store_empty
	[ $status -eq 0 ]
}

@test "Add a file to store" {
	run add_file_to_store test.bin
	[ $status -eq 0 ]
}

@test "Remove a file from store" {
	run remove_file_from_store test.bin
	[ $status -eq 0 ]

	run store_empty
	[ $status -eq 0 ] || { echo "Unexpectedly store not empty"; return 1; }
}

@test "Add and remove a file to/from store a number of times" {
	local count=0

	while [ $count -lt $ADD_REMOVE_COUNT ]; do
		run add_file_to_store test.bin
		[ $status -eq 0 ]

		run remove_file_from_store test.bin
		[ $status -eq 0 ]

		run store_empty
		[ $status -eq 0 ] || { echo "Unexpectedly store not empty"; return 1; }

		count=$(($count + 1))
	done
}

@test "Add multiple files to store" {
	for i in `seq $MULTIPLE_FILES`; do
		run add_file_to_store test-$i.bin
		[ $status -eq 0 ]
	done
}

@test "Remove multiple files from store" {
	for i in `seq $MULTIPLE_FILES`; do
		run remove_file_from_store test-$i.bin
		[ $status -eq 0 ]
	done

	run store_empty
	[ $status -eq 0 ] || { echo "Unexpectedly store not empty"; return 1; }
}

@test "Add and remove multiple files to/from store a number of times" {
	local count=0

	while [ $count -lt $MULTIPLE_ADD_REMOVE_COUNT ]; do
		for i in `seq $MULTIPLE_FILES`; do
			run add_file_to_store test-$i.bin
			[ $status -eq 0 ]
		done

		for i in `seq $MULTIPLE_FILES`; do
			run remove_file_from_store test-$i.bin
			[ $status -eq 0 ]
		done

		run store_empty
		[ $status -eq 0 ] || { echo "Unexpectedly store not empty"; return 1; }
		count=$(($count + 1))
	done
}
