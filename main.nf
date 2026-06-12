nextflow.enable.dsl=2

// 1. A dummy process to generate some output you want to commit
process GENERATE_REPORT {
    output:
    path "pipeline_summary.txt"

    script:
    """
    echo "Pipeline successfully finished at \$(date)" > pipeline_summary.txt
    """
}

// 2. The process that handles Git operations
process COMMIT_AND_PUSH {
    // Inject the Git token securely (requires Nextflow 22.09.0-edge or later)
    secret 'GIT_PAT'

    input:
    path result_file

    script:
    """
    # Configure Git identity for the commit
    git config --global user.name "Nextflow Automation Bot"
    git config --global user.email "bot@yourdomain.com"

    # Clone the repository using the Personal Access Token (PAT)
    # Replace 'github.com/your-username/your-repo.git' with your actual repo URL
    git clone https://\${GIT_PAT}@github.com/your-username/your-repo.git target_repo

    # Copy the pipeline output into the cloned repository
    cp $result_file target_repo/

    # Navigate in, commit, and push
    cd target_repo
    git add $result_file
    
    # Check if there are actually changes to commit to avoid failing the pipeline
    if git diff --staged --quiet; then
        echo "No changes to commit."
    else
        git commit -m "Automated commit: Adding $result_file from Nextflow"
        git push origin main
    fi
    """
}

workflow {
    // Generate the data
    report = GENERATE_REPORT()
    
    // Pass the generated data to the Git process
    COMMIT_AND_PUSH(report)
}
