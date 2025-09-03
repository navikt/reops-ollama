use std::env;
use std::os::unix::process::CommandExt;
use std::process::{Command, Stdio};
use std::thread;
use std::time::Duration;

fn main() {
    let model = env::var("MODEL_NAME").unwrap_or_else(|_| "llama3.2:3b".to_string());
    let ollama_home = env::var("OLLAMA_HOME").unwrap_or_else(|_| "/tmp".to_string());

    // Ensure directories
    std::fs::create_dir_all(&ollama_home).unwrap();
    std::fs::create_dir_all(format!("{}/.ollama", ollama_home)).unwrap();

    // Start ollama serve in background
    let mut child = Command::new("/usr/local/bin/ollama")
        .arg("serve")
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .spawn()
        .expect("Failed to start ollama serve");

    // Wait for server to be ready
    let client = reqwest::blocking::Client::new();
    loop {
        if let Ok(resp) = client.get("http://localhost:11434/api/tags").send() {
            if resp.status().is_success() {
                break;
            }
        }
        thread::sleep(Duration::from_secs(1));
    }

    // Check if model is present
    let output = Command::new("/usr/local/bin/ollama")
        .arg("list")
        .output()
        .expect("Failed to run ollama list");

    let output_str = String::from_utf8_lossy(&output.stdout);
    if !output_str.contains(&model) {
        println!("Model {} not present, pulling...", model);
        let status = Command::new("/usr/local/bin/ollama")
            .arg("pull")
            .arg(&model)
            .stdout(Stdio::inherit())
            .stderr(Stdio::inherit())
            .status()
            .expect("Failed to pull model");
        if !status.success() {
            eprintln!("Failed to pull model");
            std::process::exit(1);
        }
    } else {
        println!("Model {} already present", model);
    }

    // Stop background server
    let _ = child.kill();

    // Exec ollama serve in foreground
    let err = Command::new("/usr/local/bin/ollama")
        .arg("serve")
        .exec();
    eprintln!("Exec failed: {:?}", err);
    std::process::exit(1);
}
