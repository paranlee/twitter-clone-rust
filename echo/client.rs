use std::env;
use std::net::{TcpStream};
use std::io::{Read, Write};
use std::str::from_utf8;

fn main() {
	let args: Vec<String> = env::args().collect();

	if args.len() < 2 {
		println!("usage: {} <IP Address> <Port number>", args[0]);
		return;
	}

	let ip_port = &args[1];

	println!("IP Address: {}", ip_port.split(':').next().unwrap());
	println!("Port number: {}", ip_port.split(':').next_back().unwrap());

	match TcpStream::connect(ip_port) {
		Ok(mut stream) => {
			println!("Successfully connected to server in {}", ip_port);

			let msg = b"Hello!";

			stream.write(msg).unwrap();
			println!("Sent Hello, awaiting reply...");

			let mut data = [0 as u8; 6]; // using 6 byte buffer
			match stream.read_exact(&mut data) {
				Ok(_) => {
					if &data == msg {
						println!("Reply is ok!");
					} else {
						let text = from_utf8(&data).unwrap();
						println!("Unexpected reply: {}", text);
					}
				},
				Err(e) => {
					println!("Failed to receive data: {}", e);
				}
			}
		},
		Err(e) => {
			println!("Failed to connect: {}", e);
		}
	}
	println!("Terminated.");
}
