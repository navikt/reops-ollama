use std::env;
use std::os::unix::process::CommandExt;
use std::process::{Command, Stdio};
use std::thread;
use std::time::Duration;
use std::fs;
use std::io;
use std::path::Path;

fn main() {
    let model = env::var("MODEL_NAME").unwrap_or_else(|_| "llama3.2:3b".to_string());
    let ollama_home = env::var("OLLAMA_HOME").unwrap_or_else(|_| "/tmp".to_string());

    // Ensure directories
    std::fs::create_dir_all(&ollama_home).unwrap();
    std::fs::create_dir_all(format!("{}/.ollama", ollama_home)).unwrap();

    // If the runtime writable home is /tmp and it's empty, copy pre-pulled models
    // from /var/lib/ollama/.ollama (present in the image) into /tmp/.ollama so
    // the K8s emptyDir overlay doesn't hide pre-baked models.
    let image_models = Path::new("/var/lib/ollama/.ollama");
    let runtime_models = Path::new(&format!("{}/.ollama", ollama_home));
    fn is_dir_nonempty(p: &Path) -> bool {
        match fs::read_dir(p) {
            Ok(mut it) => it.next().is_some(),
            Err(_) => false,
        }
    }

    if image_models.exists() && !is_dir_nonempty(runtime_models) {
        // copy recursively
        fn copy_dir_all(src: &Path, dst: &Path) -> io::Result<()> {
            fs::create_dir_all(dst)?;
            for entry in fs::read_dir(src)? {
                let entry = entry?;
                let file_type = entry.file_type()?;
                let src_path = entry.path();
                let dst_path = dst.join(entry.file_name());
                if file_type.is_dir() {
                    copy_dir_all(&src_path, &dst_path)?;
                } else if file_type.is_file() {
                    fs::copy(&src_path, &dst_path)?;
                }
            }
            Ok(())
        }

        if let Err(e) = copy_dir_all(image_models, runtime_models) {
            eprintln!("Failed to copy models from image: {}", e);
        } else {
            // attempt to make writable
            let _ = Command::new("/bin/chmod").arg("-R").arg("0777").arg(runtime_models).status();
            println!("Copied pre-pulled models into {}", runtime_models.display());
        }
    }

    // Start ollama serve in background
    let mut child = Command::new("/usr/local/bin/ollama")
        .arg("serve")
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .spawn()
        .expect("Failed to start ollama serve");

    // Wait for server to be ready
    loop {
        if let Ok(resp) = ureq::get("http://localhost:11434/api/tags").call() {
            if resp.status() == 200 {
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
