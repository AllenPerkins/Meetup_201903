# -----------------------------------------------------------------------------
# Author: Allen Perkins
# Date:   2019-01-24
# Obj:    Use the two command line parameters, a URL and a file name, to
#         download the URL and save it to the named file.
#
#         The path for where the file will be saved is set as a variable. Be
#         sure to check that it where you want the file.
#
# -----------------------------------------------------------------------------
# How to execute this script from the command line:
# Prompt$> ./GetBeigeBook.sh 'https://www.federalreserve.gov/monetarypolicy/beigebook201901.htm' '201901.txt'
#
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Revision history:
# 
# Date        Author            Purpose                                   TAG
# -----------------------------------------------------------------------------
# 2019-01-24  Allen Perkins     Original (001.000.000)
# -----------------------------------------------------------------------------
#
echo Retreiving the contents of: $1
echo Into a file named: $2
  # Confirm the caller's params.
P1='_P1'
P2='_P2'
  # Temporary file extensions for the stream editor.
Path='/mnt/c/temp/'
  # Prefix file names with the path.
  # This is where the downloaded files are placed.
curl $1 | html2text > $Path$2
  # curl will pull the contents of the URL, parameter $1.
  # html2text will convert the bytestream to text using utf-8.
  # The > passes the output to a file named by parameter $2.
sed '/^ '/d $Path$2 > $Path$2$P1
  # sed is the stream editor.
  # '/^ ' anchors the regex to the beginning of each line.
  # /d deletes the line if it begins with a space.
  # The > writes the results to a temporary file with the extension _P1.
sed '/_/d' $Path$2$P1 > $Path$2$P2
  # This regex deletes lines if an underbar appears in that line.
  # The > writes the results to a temporary file with the extension _P2.
mv $Path$2$P2 $Path$2
  # The mv (move) command renames the final temp file back to our param $2.
rm $Path$2$P1
  # The rm (remove) command deletes the first intermediate temporary file.
if grep -q 'Page not found' $Path$2;
    # Perform a test on the contents of the URL we just downloaded.
    # The grep utility will search the input file, in our case the file whose
    # name is param $2.
    # Check whether the 'Page not found' string was returned by the website.
  then
    echo 'No report for this month. Removing downloaded content.'
      # Give the user some feedback.
    rm $Path$2
      # If the string was found, then remove the file.
  else
    echo 'Report for this month was downloaded, parsed, and saved.'
      # Give the user some feedback.
      # If the string was not found, then keep the file.
      # The months when a Beige Book report is issued vary, so not finding
      # one for a specific month is not a bad thing. There are usually
      # eight per year.
fi
  # End of file content testing.
