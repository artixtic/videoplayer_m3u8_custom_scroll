#!/bin/bash

# Script to analyze M3U8 file and get actual durations of all TS segments
# Usage: ./analyze_m3u8_durations.sh <M3U8_URL> [output_file]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if M3U8 URL is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: M3U8 URL is required${NC}"
    echo "Usage: $0 <M3U8_URL> [output_file] [max_segments]"
    echo "Example: $0 https://example.com/playlist.m3u8 results.txt"
    echo "Example: $0 https://example.com/playlist.m3u8 results.txt 10  # Analyze first 10 segments only"
    exit 1
fi

M3U8_URL="$1"
OUTPUT_FILE="${2:-m3u8_durations_analysis_$(date +%Y%m%d_%H%M%S).txt}"
MAX_SEGMENTS="${3:-999999}"  # Default: analyze all segments, can be limited for testing

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}M3U8 Duration Analysis Tool${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "M3U8 URL: $M3U8_URL"
echo "Output file: $OUTPUT_FILE"
if [ "$MAX_SEGMENTS" != "999999" ]; then
    echo "Max segments: $MAX_SEGMENTS"
fi
echo ""

# Check if ffprobe is available
if ! command -v ffprobe &> /dev/null; then
    echo -e "${RED}Error: ffprobe is not installed${NC}"
    echo "Install it with: brew install ffmpeg"
    exit 1
fi

# Check if bc is available
if ! command -v bc &> /dev/null; then
    echo -e "${RED}Error: bc (calculator) is not installed${NC}"
    echo "Install it with: brew install bc"
    exit 1
fi

echo -e "${GREEN}✓ ffprobe found${NC}"
echo -e "${GREEN}✓ bc found${NC}"
if [ "$MAX_SEGMENTS" != "999999" ]; then
    echo -e "${YELLOW}⚠ Limiting analysis to first $MAX_SEGMENTS segments${NC}"
fi
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "${YELLOW}📥 Downloading M3U8 file...${NC}"
curl -s "$M3U8_URL" -o "$TEMP_DIR/playlist.m3u8"

if [ ! -s "$TEMP_DIR/playlist.m3u8" ]; then
    echo -e "${RED}Error: Failed to download M3U8 file${NC}"
    exit 1
fi

echo -e "${GREEN}✓ M3U8 file downloaded${NC}"
echo ""

# Extract base URL
BASE_URL="${M3U8_URL%/*}/"

# Parse M3U8 and extract segments
echo -e "${YELLOW}📊 Parsing M3U8 segments...${NC}"

SEGMENT_COUNT=0
TOTAL_DECLARED="0"
TOTAL_ACTUAL="0"
FAILED_COUNT=0

# Initialize output file
cat > "$OUTPUT_FILE" << EOF
M3U8 Duration Analysis Report
Generated: $(date)
M3U8 URL: $M3U8_URL

================================================================================
Segment Analysis
================================================================================
EOF

# Create CSV file for easier analysis
CSV_FILE="${OUTPUT_FILE%.txt}.csv"
echo "Index,TS_File_Name,Declared_Duration(s),Actual_Duration(s),Difference(s),File_Size(KB),Status" > "$CSV_FILE"

# Process M3U8 file line by line
CURRENT_DURATION=""
while IFS= read -r line || [ -n "$line" ]; do
    line=$(echo "$line" | tr -d '\r')
    
    # Check for EXTINF line (contains duration)
    if [[ "$line" =~ ^#EXTINF: ]]; then
        # Extract duration - format can be #EXTINF:8, or #EXTINF:8.0, or #EXTINF:8.0,
        # Remove #EXTINF: prefix, then extract the number (may have comma or space after)
        CURRENT_DURATION=$(echo "$line" | sed 's/^#EXTINF://' | sed 's/[^0-9.].*$//' | grep -oE '^[0-9]+\.?[0-9]*' | head -1)
        
        # Validate we got a number
        if [ -z "$CURRENT_DURATION" ] || ! [[ "$CURRENT_DURATION" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            echo -e "${YELLOW}Warning: Could not parse duration from: $line${NC}"
            CURRENT_DURATION=""
        fi
    fi
    
    # Check for TS file line
    if [[ "$line" =~ \.ts ]] && [ -n "$CURRENT_DURATION" ]; then
        # Check if we've reached the max segments limit
        if [ $SEGMENT_COUNT -ge $MAX_SEGMENTS ]; then
            echo -e "${YELLOW}⚠ Reached maximum segment limit ($MAX_SEGMENTS)${NC}"
            break
        fi
        
        SEGMENT_COUNT=$((SEGMENT_COUNT + 1))
        
        # Build full URL
        if [[ "$line" =~ ^http ]]; then
            SEGMENT_URL="$line"
        else
            SEGMENT_URL="${BASE_URL}${line}"
        fi
        
        # Extract filename
        FILENAME=$(basename "$SEGMENT_URL" | cut -d'?' -f1)
        
        echo -e "${BLUE}[$SEGMENT_COUNT]${NC} Processing: $FILENAME"
        
        # Clean and validate duration - remove any non-numeric characters except decimal point
        # Strip whitespace, remove 's' suffix, and ensure it's a valid number
        CURRENT_DURATION_CLEAN=$(echo "$CURRENT_DURATION" | sed 's/[^0-9.]//g' | tr -d '[:space:]')
        
        # Validate duration before proceeding
        if [ -z "$CURRENT_DURATION_CLEAN" ] || ! [[ "$CURRENT_DURATION_CLEAN" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            echo -e "  ${RED}Error: Invalid duration format: '$CURRENT_DURATION'${NC}"
            CURRENT_DURATION=""
            continue
        fi
        
        # Use cleaned version
        CURRENT_DURATION="$CURRENT_DURATION_CLEAN"
        
        echo "  Declared duration: ${CURRENT_DURATION}s"
        
        # Get actual duration using ffprobe
        ACTUAL_DURATION=""
        FILE_SIZE=""
        STATUS=""
        
        if ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$SEGMENT_URL" 2>/dev/null | grep -q .; then
            ACTUAL_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$SEGMENT_URL" 2>/dev/null | head -1)
            
            if [ -n "$ACTUAL_DURATION" ] && [ "$ACTUAL_DURATION" != "N/A" ]; then
                # Clean actual duration (remove any whitespace or non-numeric chars)
                ACTUAL_DURATION=$(echo "$ACTUAL_DURATION" | tr -d '[:space:]' | grep -oE '[0-9]+\.?[0-9]*' | head -1)
                
                # Validate both values are numeric before calculation
                # Double-check and clean both values
                CURRENT_DURATION=$(echo "$CURRENT_DURATION" | sed 's/[^0-9.]//g')
                ACTUAL_DURATION=$(echo "$ACTUAL_DURATION" | sed 's/[^0-9.]//g')
                
                if [[ "$ACTUAL_DURATION" =~ ^[0-9]+\.?[0-9]*$ ]] && [[ "$CURRENT_DURATION" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                    # Calculate difference using bc with scale for precision
                    DIFF=$(echo "scale=6; $ACTUAL_DURATION - $CURRENT_DURATION" | bc)
                    # Calculate absolute value (handle negative by multiplying by -1 if needed)
                    DIFF_ABS=$(echo "scale=6; define abs(x) { if (x < 0) return (-x) else return (x) }; abs($DIFF)" | bc 2>/dev/null || echo "$DIFF" | sed 's/^-//')
                    # If the above fails, use simple approach
                    if [ -z "$DIFF_ABS" ] || ! [[ "$DIFF_ABS" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                        DIFF_ABS=$(echo "$DIFF" | sed 's/^-//')
                    fi
                else
                    echo -e "  ${RED}Error: Invalid numeric values for calculation${NC}"
                    ACTUAL_DURATION=""
                fi
                
                # Get file size
                FILE_SIZE_BYTES=$(curl -sI "$SEGMENT_URL" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
                if [ -n "$FILE_SIZE_BYTES" ]; then
                    FILE_SIZE=$(echo "scale=1; $FILE_SIZE_BYTES / 1024" | bc)
                else
                    FILE_SIZE="N/A"
                fi
                
                # Only proceed if we have valid values
                if [ -n "$ACTUAL_DURATION" ] && [ -n "$DIFF" ]; then
                    # Determine status
                    if (( $(echo "$DIFF_ABS > 0.5" | bc -l) )); then
                        STATUS="⚠️ MISMATCH"
                        echo -e "  ${RED}Actual duration: ${ACTUAL_DURATION}s (diff: ${DIFF}s)${NC}"
                    else
                        STATUS="✓ OK"
                        echo -e "  ${GREEN}Actual duration: ${ACTUAL_DURATION}s (diff: ${DIFF}s)${NC}"
                    fi
                    
                    echo "  File size: ${FILE_SIZE} KB"
                    
                    # Update totals (ensure both values are clean numbers)
                    CURRENT_NUM=$(echo "$CURRENT_DURATION" | sed 's/[^0-9.]//g')
                    ACTUAL_NUM=$(echo "$ACTUAL_DURATION" | sed 's/[^0-9.]//g')
                    if [[ "$CURRENT_NUM" =~ ^[0-9]+\.?[0-9]*$ ]] && [[ "$ACTUAL_NUM" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                        TOTAL_DECLARED=$(echo "scale=6; $TOTAL_DECLARED + $CURRENT_NUM" | bc)
                        TOTAL_ACTUAL=$(echo "scale=6; $TOTAL_ACTUAL + $ACTUAL_NUM" | bc)
                    fi
                    
                    # Write to output file
                    cat >> "$OUTPUT_FILE" << EOF

Segment #$SEGMENT_COUNT: $FILENAME
  Declared Duration: ${CURRENT_DURATION}s
  Actual Duration: ${ACTUAL_DURATION}s
  Difference: ${DIFF}s
  File Size: ${FILE_SIZE} KB
  Status: $STATUS
EOF
                    
                    # Write to CSV
                    echo "$SEGMENT_COUNT,\"$FILENAME\",$CURRENT_DURATION,$ACTUAL_DURATION,$DIFF,$FILE_SIZE,\"$STATUS\"" >> "$CSV_FILE"
                else
                    STATUS="❌ FAILED"
                    FAILED_COUNT=$((FAILED_COUNT + 1))
                    echo -e "  ${RED}Failed to calculate duration difference${NC}"
                fi
            else
                STATUS="❌ FAILED"
                FAILED_COUNT=$((FAILED_COUNT + 1))
                echo -e "  ${RED}Failed to get duration${NC}"
                
                cat >> "$OUTPUT_FILE" << EOF

Segment #$SEGMENT_COUNT: $FILENAME
  Declared Duration: ${CURRENT_DURATION}s
  Actual Duration: FAILED
  Status: $STATUS
EOF
                
                echo "$SEGMENT_COUNT,\"$FILENAME\",$CURRENT_DURATION,N/A,N/A,N/A,\"$STATUS\"" >> "$CSV_FILE"
            fi
        else
            STATUS="❌ FAILED"
            FAILED_COUNT=$((FAILED_COUNT + 1))
            echo -e "  ${RED}Failed to access segment${NC}"
            
            cat >> "$OUTPUT_FILE" << EOF

Segment #$SEGMENT_COUNT: $FILENAME
  Declared Duration: ${CURRENT_DURATION}s
  Actual Duration: FAILED (Cannot access)
  Status: $STATUS
EOF
            
            echo "$SEGMENT_COUNT,\"$FILENAME\",$CURRENT_DURATION,N/A,N/A,N/A,\"$STATUS\"" >> "$CSV_FILE"
        fi
        
        echo ""
        
        # Reset current duration (important for next iteration)
        CURRENT_DURATION=""
        CURRENT_DURATION_CLEAN=""
    fi
done < "$TEMP_DIR/playlist.m3u8"

# Calculate summary
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Summary${NC}"
echo -e "${YELLOW}========================================${NC}"

TOTAL_DIFF=$(echo "$TOTAL_ACTUAL - $TOTAL_DECLARED" | bc)
TOTAL_DIFF_ABS=$(echo "if ($TOTAL_DIFF < 0) -$TOTAL_DIFF else $TOTAL_DIFF" | bc)

echo "Total segments analyzed: $SEGMENT_COUNT"
echo "Successfully analyzed: $((SEGMENT_COUNT - FAILED_COUNT))"
echo "Failed: $FAILED_COUNT"
echo ""
echo "Total declared duration: ${TOTAL_DECLARED}s ($(echo "scale=1; $TOTAL_DECLARED / 60" | bc) minutes)"
echo "Total actual duration: ${TOTAL_ACTUAL}s ($(echo "scale=1; $TOTAL_ACTUAL / 60" | bc) minutes)"
echo "Total difference: ${TOTAL_DIFF}s ($(echo "scale=1; $TOTAL_DIFF_ABS / 60" | bc) minutes)"

# Append summary to output file
cat >> "$OUTPUT_FILE" << EOF

================================================================================
Summary
================================================================================
Total segments analyzed: $SEGMENT_COUNT
Successfully analyzed: $((SEGMENT_COUNT - FAILED_COUNT))
Failed: $FAILED_COUNT

Total declared duration: ${TOTAL_DECLARED}s ($(echo "scale=1; $TOTAL_DECLARED / 60" | bc) minutes)
Total actual duration: ${TOTAL_ACTUAL}s ($(echo "scale=1; $TOTAL_ACTUAL / 60" | bc) minutes)
Total difference: ${TOTAL_DIFF}s ($(echo "scale=1; $TOTAL_DIFF_ABS / 60" | bc) minutes)

CSV file: $CSV_FILE
================================================================================
EOF

echo ""
echo -e "${GREEN}✓ Analysis complete!${NC}"
echo "Results saved to: $OUTPUT_FILE"
echo "CSV data saved to: $CSV_FILE"
echo ""

