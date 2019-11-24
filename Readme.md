# Learning Purpose

This is a Visual Studio Community Edition 2017 solution that was presented at the March 5, 2019 Birmingham Data Architecture and Data Science Meetup (https://www.meetup.com/Birmingham-Data-Architecture-and-Data-Science/).

Caution, this is not a solution for a complete beginner. Even though there are a lot of comments to help, some tacit knowledge of the tools is expected. For example, the PostgreSQL scripts are provided to build the tables needed; however, you must know how to create a database and connect to it. By way of another example, the scripts have parameters for paths, so you will need to create paths on your system and update those parameters accordingly. Finally, the solution uses the Windows System for Linux which is a free add-on for Windows 10, so you must know how to setup and configure a running Linux environment and understand how the Linux file system paths map to the Windows file system paths.

# Data Science Purpose
Demonstrate a number of data science techniques and answer a question in the process. The question: Do the statements in the Federal Reserve Beige Book align with the numerical economic statistics that are published in the same month as the Beige Book? If the statements do not align, then does the Beige Book lead or lag the numerical economic statistics?

# Process

- Pull economic data from a federal government public API (economic statistics).
- Transform the economic data as needed to support visualization and analysis.
- Pull free form text data from a web page (the text of the Beige Book).
- Use natural language processing to extract statements about economic indicators from the free form text..
- Construct visualizations to determine whether statements about economic indicators align with the actual economic metrics.

# Tools

R, PowerShell, PostgreSQL, and a bash script.