# Summary

This repository contains a mock debug adapter and a partially-done
Debug Adapter Protocol implementation for Pike.

It also contains quicktype-generated Pike code from the Protocol's
specification JSON Schema[*]:
https://app.quicktype.io/#lang=pike
https://github.com/Microsoft/vscode-debugadapter-node/blob/master/debugProtocol.json

Works for Pike v8.0^.

Debug Adapter Protocol's home page:
https://microsoft.github.io

# Example usage

Assuming that the path to a Pike interpreter is present in `$PATH`.

`$ pike adapter.pike -h` displays a brief description of available
command line arguments.

`$ pike adapter.pike` runs a Debug Adapter communicating through stdio.
Used by clients to communicate with the adapter using `stdin` and `stdout`.
Running it from terminal is good for nothing, unless you want to type DAP
messages manually.

`$ pike adapter.pike -p` runs a Debug Adapter listening on default port (4711).
You can set the port by adding a value to the `-p` argument, for example
`$ pike adapter.pike -p2138` runs an adapter listening on port 2138.

`$ pike adapter.pike -p<port> -d` is probably what you want. It runs the
adapter listening on a chosen port with debug messages sent to `stderr`.
It alows you to see what messages are being exchanged between the adapter
and client.

# Working with editors

There is a big choice of editors supporting the Debug Adapter Protocol,
(https://microsoft.github.io/debug-adapter-protocol/implementors/tools/)
however this repository comes with Visual Studio Code's Extension Manifest
(https://code.visualstudio.com/api/references/extension-manifest).

To start playing with the adapter using Visual Studio Code:
1. Clone this repository into VSCode's extenstion directory, which usually is
`~/.vscode/extensions`.
2. Open a terminal and `cd` into the repository's top catalog,
which will probably be `$ cd ~/.vscode/extensions/pike-debug-adapter-playground`
3. Open Visual Studio Code in the current working directory (`$ code .`).
4. Run the adapter from a terminal as described in the previous section.
`$ pike adapter.pike -p -d`
(VSCode has an integrated terminal, if you wish).
5. Choose the configuration `lauch-socket` or `attach-scket` and press the
green button.
6. Interact with the editor and observe what messages are exchanged between
the client and the adapter.


# Feedback
Do not hesitate to open an issue or a pull request, or contact me via github/
email. Your feedback is more than appreciated.



[*] Actually, the quicktype-generated file has been created with applying a tiny
change to quicktype's Pike renderer.

To generate, clone the branch with hacked Pike renderer:
https://github.com/mkrawczuk/quicktype/tree/protocol_schema

After installation, run the following command from the project's top catalog:
`$ ./script/quicktype -s schema "https://raw.githubusercontent.com/Microsoft/vscode-debugadapter-node/master/debugProtocol.json#/definitions/" -o DebugAdapterProtocolGenerated.pmod`