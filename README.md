# ScriptHub
ScriptHub contains a collection of useful libraries from AutoHotkey forums.

## Adding libraries
ScriptHub libraries are maintained up-to-date with a helper script ScriptHubUpdater located in `v2/Descolada/ScriptHubUpdater`. In the assets folder is the `forums.json` file which contains metadata about the libraries and how to fetch them from the forums. Entries are categorized by author names, and each entry must have the `main` field (name of the library file) and `url` linking to the forums. Optional fields are `codebox` which determines which code box should be retrieved (counting starts from the top, from 1, and negative numbers are allowed), and `required_substring` which adds an optional check to verify the correct code was retrieved. `forums.json` may be prettified (consistently formatted) by running `assets/format_json.ahk`. 

If a corresponding file to a library entry is not found in ScriptHub then first Wayback Machine is queried for the forums post change history and git commits with the snapshot dates are created. Then the live forums are queried for the latest version and if any changes are detected to the file then a new commit is made. Adding commits requires `git` to be installed and properly set up. 

By default live forums are queried once every 30 days for a package. To force a check early, manually delete the `last_check` key from the entry. 