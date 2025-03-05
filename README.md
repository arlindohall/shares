# Shares

Some scripts for parsing the share reports on Morgan Stanley Solium that I use to prep for tax season.

## Getting Started

To use these, you need to pull the report and copy it to the `input` directory. That means:

1. Open your Solium account
2. Go to "Activity"
3. Click "Reports" and generate a report for "All Available History"
4. Configure the report to use:
  - "Adjusted" instead of "Original"
  - "Web" instead of "PDF"
  - "Full" instead of "Simplified"
5. Right-click and choose "Inspect Element" anywhere on the *report itself*
6. This opens the inspect window, make sure you're within the iframe
7. Right-click the `iframe` element and choose "Copy" -> "HTML"
8. In a terminal in this repo, run `pbpaste > input/adjusted-full-web.html`
