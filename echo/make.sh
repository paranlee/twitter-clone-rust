
rustc +nightly -Zinstrument-mcount -C passes="ee-instrument<post-inline>" server.rs -o server
rustc +nightly -Zinstrument-mcount -C passes="ee-instrument<post-inline>" client.rs -o client
