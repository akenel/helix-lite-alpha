const profileContent = $item(0).$node['Read Profile Text'].json.text;
const briefContent = $item(0).$node['Read Brief Text'].json.text;
// Construct the prompt for the AI\nconst aiPrompt = `
// Analyze the following user profile and brief, 
// and then generate an offer status.
User Profile: ${profileContent}
User Brief: ${briefContent}
Generated Offer Status (start with 'Offer_Status: '):


return [{ json: { aiPrompt } }];