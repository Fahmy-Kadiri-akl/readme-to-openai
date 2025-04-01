#!/usr/bin/env nu
def check_readme_api_key [] {
    if "README_API_KEY" in $env {
        print $"(ansi green_bold)Success:(ansi reset) README_API_KEY environment variable is set"
    } else {
        print $"(ansi red_bold)Error:(ansi reset) README_API_KEY environment variable is not set"
        print $"Please set the environment variable with: (ansi cyan)export README_API_KEY=your_token_value(ansi reset)"
        exit 1
    }
}
def check_openai_api_key [] {
    if "OPENAI_API_KEY" in $env {
        print $"(ansi green_bold)Success:(ansi reset) OPENAI_API_KEY environment variable is set"
    } else {
        print $"(ansi red_bold)Error:(ansi reset) OPENAI_API_KEY environment variable is not set"
        print $"Please set the environment variable with: (ansi cyan)export OPENAI_API_KEY=your_token_value(ansi reset)"
        exit 1
    }
}
def check_vector_store_id [] {
    if "VECTOR_STORE_ID" in $env {
        print $"(ansi green_bold)Success:(ansi reset) VECTOR_STORE_ID environment variable is set"
    } else {
        print $"(ansi red_bold)Error:(ansi reset) VECTOR_STORE_ID environment variable is not set"
        print $"Please set the environment variable with: (ansi cyan)export VECTOR_STORE_ID=your_vector_store_id(ansi reset)"
        exit 1
    }
}
def upload_file_to_openai [openaiHeaders:list<string> fileFullPath:string] {
    # We have to use curl to upload the file instead of native nu shell or else the file name will not show up in the OpenAI file list
    let max_retries = 5
    let base_wait_time = 1  # Initial wait time in seconds
    
    mut attempts = 0
    while $attempts < $max_retries {
        $attempts = $attempts + 1
        let currentAttempt = $attempts
        
        # Attempt to upload file
        let result = do {
            let fileObject = (^curl -s https://api.openai.com/v1/files -H $"Authorization: Bearer ($env.OPENAI_API_KEY)" -F purpose="assistants" -F $"file=@($fileFullPath)" | from json)
            
            # Check if the response contains an ID
            if "id" in $fileObject {
                let fileId = ($fileObject | get id)
                print $"File ID Created: (ansi green_bold)($fileId)(ansi reset)"
                return $fileId
            } else {
                # No ID in response
                print $"(ansi yellow_bold)Warning:(ansi reset) Failed to get file ID from response on attempt ($currentAttempt)/($max_retries)"
                return null
            }
        } catch {
            print $"(ansi yellow_bold)Warning:(ansi reset) Error uploading file on attempt ($currentAttempt)/($max_retries)"
        }
        
        # If we got a result, return it
        if $result != null {
            return $result
        }
        
        # Calculate exponential backoff time
        if $attempts < $max_retries {
            let wait_time = ($base_wait_time * (2 ** ($attempts - 1)))
            print $"Retrying in ($wait_time) seconds..."
            sleep ($wait_time * 1sec)
        }
    }
    
    # If we get here, we've failed all retries
    print $"(ansi red_bold)Error:(ansi reset) Failed to upload file after ($max_retries) attempts"
    exit 1
}
def add_file_to_vector_store [openaiHeaders:list<string> vectorStoreId:string fileId:string categoryName:string docSlug:string docName:string parentName:string = "none" parentSlug:string = "none" grandParentName:string = "none" grandParentSlug:string = "none"] {
    let docUrl = $"https://docs.akeyless.io/docs/($docSlug)"
    let vectorStoreUrl = $"https://api.openai.com/v1/vector_stores/($vectorStoreId)/files"
    let payload = { file_id: $fileId, attributes: 
        { category: $categoryName, parent_name: $parentName, parent_slug: $parentSlug, grandparent_name: $grandParentName, grandparent_slug: $grandParentSlug, url: $docUrl, doc_name: $docName, doc_type: 'public-docs' } }
    let vectorStoreObject = (http post --content-type "application/json" --headers $openaiHeaders $vectorStoreUrl $payload)
    return $vectorStoreObject
}
# Run the checks
check_readme_api_key
check_openai_api_key
check_vector_store_id
let uploadToOpenAI = false
# Create data directory if it doesn't exist
let data_dir = (pwd | path join "data" "docs")
if ($data_dir | path exists) == false {
    mkdir $data_dir
}
let creds = $"Basic ($env.README_API_KEY)"
let headers = [("authorization") ($creds)]
let openaiCreds = $"Bearer ($env.OPENAI_API_KEY)"
let openaiHeaders = [("authorization") ($openaiCreds)]
let vectorStoreId = $env.VECTOR_STORE_ID
let categories = (http get --headers $headers https://dash.readme.com/api/v1/categories)
let cats = ($categories | where reference == false | sort-by order | select title slug)
$cats | each { |catrow|
    let categoryTitle = $catrow.title
    let categorySlug = $catrow.slug
    let url = $"https://dash.readme.com/api/v1/categories/($categorySlug)/docs"
    print $"Processing category: (ansi cyan_bold)($categoryTitle)(ansi reset)"
    let docsFromCategory = (http get --headers $headers $url)
    let catDir = (pwd | path join "data" "docs" ($categoryTitle | into string))
    if ($catDir | path exists) == false {
        mkdir $catDir
    }
    $docsFromCategory | each { |doc|
        # Get the title of the doc
        let docTitle = $doc.title
        # Get the slug of the doc
        let docSlug = $doc.slug
        # Get the hidden status of the doc
        let docHidden = $doc.hidden
        # If the doc is hidden, skip it
        if $docHidden {
            print $"Skipping hidden doc: (ansi yellow_bold)($docTitle)(ansi reset) from category: (ansi cyan_bold)($categoryTitle)(ansi reset)"
            return
        }
        # Get the full doc from the API
        let docUrl = $"https://dash.readme.com/api/v1/docs/($docSlug)"
        print $"Processing doc: (ansi yellow_bold)($docTitle)(ansi reset) from category: (ansi cyan_bold)($categoryTitle)(ansi reset)"
        # Get the full doc from the API
        let docFull = (http get --headers $headers $docUrl)
        # Check if the doc has children
        let hasChildren = ($doc.children | length) > 0
        # If the doc has children, create a directory named after the parent title and do not alter the directory name
        if $hasChildren {
            # Get the children of the doc
            let children = $doc.children
            # Create directory named after the parent title and do not alter the directory name
            let parentDir = (pwd | path join "data" "docs" ($catDir | into string) ($docTitle | into string))
            # Create the parent directory if it doesn't exist
            if ($parentDir | path exists) == false {
                mkdir $parentDir
            }
            # Write the markdown from the child docs to the parent directory
            $children | sort-by order | each { |child|
                # Get the title of the child doc
                let childTitle = $child.title
                # Get the slug of the child doc
                let childSlug = $child.slug
                # Get the hidden status of the child doc
                let childHidden = $child.hidden
                # If the child doc is hidden, skip it
                if $childHidden {
                    print $"Skipping hidden child doc: (ansi yellow_bold)($childTitle)(ansi reset) from parent doc: (ansi cyan_bold)($docTitle)(ansi reset)"
                    return
                }
                # Get the hidden status of the grand children
                let hasGrandChildren = ($child.children | length) > 0
                # If the child doc has grand children, create a directory named after the child title and do not alter the directory name
                if $hasGrandChildren {
                    # Get the grand children of the child doc
                    let grandChildren = $child.children
                    # Create directory named after the child title and do not alter the directory name
                    let grandChildDir = (pwd | path join "data" "docs" ($parentDir | into string) ($childTitle | into string))
                    # Create the grand child directory if it doesn't exist
                    if ($grandChildDir | path exists) == false {
                        mkdir $grandChildDir
                    }
                    $grandChildren | sort-by order | each { |grandChild|
                        # Get the title of the grand child doc
                        let grandChildTitle = $grandChild.title
                        # Get the slug of the grand child doc
                        let grandChildSlug = $grandChild.slug
                        # Get the hidden status of the grand child doc
                        let grandChildHidden = $grandChild.hidden
                        # If the grand child doc is hidden, skip it
                        if $grandChildHidden {
                            print $"Skipping hidden grand child doc: (ansi magenta_bold)($grandChildTitle)(ansi reset) from parent doc: (ansi yellow_bold)($childTitle)(ansi reset)"
                            return
                        }
                        # Get the full doc from the API
                        let grandChildUrl = $"https://dash.readme.com/api/v1/docs/($grandChildSlug)"
                        # Get the full doc from the API
                        let grandChildFull = (http get --headers $headers $grandChildUrl)
                        # Write the markdown from the grand child doc to the grand child directory
                        let grandChildFileName = $"($grandChildSlug).md"
                        # Create the file full path
                        let grandChildFileFullPath = ($grandChildDir | path join $grandChildFileName)
                        # Create the json full path
                        let grandChildJsonFullPath = ($grandChildFileFullPath | str replace -a -r '(.+?).md' '$1.json')
                        # Write the markdown from the grand child doc to the grand child directory
                        $grandChildFull | get body | str replace -a -r '\(doc:([^)]+)\)' '(https://docs.akeyless.io/docs/$1)' | save -f $grandChildFileFullPath
                        if $uploadToOpenAI {
                            print $"Uploading file to OpenAI: (ansi white_bold)($grandChildFileFullPath)(ansi reset)"
                            # Upload the file to OpenAI
                            let fileId = (upload_file_to_openai $openaiHeaders $grandChildFileFullPath)
                            let vectorStoreObject = (add_file_to_vector_store $openaiHeaders $vectorStoreId $fileId $categoryTitle $grandChildSlug $grandChildTitle $childTitle $childSlug $docTitle $docSlug )
                            print $"Vector store object status: (ansi green_bold)($vectorStoreObject | get status)(ansi reset)"
                        }
                    }
                }
                # Get the full doc from the API
                let childUrl = $"https://dash.readme.com/api/v1/docs/($childSlug)"
                # Get the full doc from the API
                let childFull = (http get --headers $headers $childUrl)
                # Write the markdown from the child doc to the parent directory
                let fileName = $"($childSlug).md"
                # Create the file full path
                let childFileFullPath = ($parentDir | path join $fileName)
                # Write the markdown from the child doc to the parent directory
                $childFull | get body | str replace -a -r '\(doc:([^)]+)\)' '(https://docs.akeyless.io/docs/$1)' | save -f $childFileFullPath
                if $uploadToOpenAI {
                    print $"Uploading file to OpenAI: (ansi white_bold)($childFileFullPath)(ansi reset)"
                    # Upload the file to OpenAI
                    let fileId = (upload_file_to_openai $openaiHeaders $childFileFullPath)
                    let vectorStoreObject = (add_file_to_vector_store $openaiHeaders $vectorStoreId $fileId $categoryTitle $childSlug $childTitle $docTitle $docSlug )
                    print $"Vector store object status: (ansi green_bold)($vectorStoreObject | get status)(ansi reset)"
                }
            }
        }
        # Write the markdown from the doc to the category directory
        let fileName = $"($docSlug).md"
        # Create the file full path
        let docFileFullPath = ($catDir | path join $fileName)
        # Write the markdown from the doc to the category directory
        $docFull | get body | str replace -a -r '\(doc:([^)]+)\)' '(https://docs.akeyless.io/docs/$1)' | save -f $docFileFullPath
        if $uploadToOpenAI {
            print $"Uploading file to OpenAI: (ansi white_bold)($docFileFullPath)(ansi reset)"
            # Upload the file to OpenAI
            let fileId = (upload_file_to_openai $openaiHeaders $docFileFullPath)
            let vectorStoreObject = (add_file_to_vector_store $openaiHeaders $vectorStoreId $fileId $categoryTitle $docSlug $docTitle )
            print $"Vector store object status: (ansi green_bold)($vectorStoreObject | get status)(ansi reset)"
        }
    }
}
