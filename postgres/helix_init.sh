CREATE TABLE IF NOT EXISTS helix_table (
    -- Primary key and unique identifiers
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    
    -- Status and Lifecycle
    stage VARCHAR(50),
    notes TEXT,
    outreach_status VARCHAR(50) NOT NULL DEFAULT 'initialized',
    
    -- Workflow and Timestamps
    workflow_id VARCHAR(255) NOT NULL,
    workflow_name VARCHAR(255) NOT NULL,
    wf_run_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    response_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Contact Details
    contact_title VARCHAR(255),
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(255),
    company_name VARCHAR(255),
    
    -- MinIO File Links
    minio_contact_profile_url VARCHAR(2048),
    minio_marketing_brief_url VARCHAR(2048),
    minio_ai_output_url VARCHAR(2048),
    
    -- AI Interaction Details
    ai_prompt_text TEXT,
    ai_raw_response_text TEXT,
    
    -- Public Links for Prospect
    minio_ai_output_public_url VARCHAR(2048),
    minio_ai_output_public_url_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit and Tracking
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);