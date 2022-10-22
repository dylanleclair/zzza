# if we're at the spot to place text
        if(position == 177 or position == 197):
            mode = "ENC_TEXT"
            print(length)
            val = encode(length, previous_char)
            data.append(val)
            length = 1
            previous_char = current_char

        # this data comes directly from the image
        if (mode == "ENC_COL"):

            # If this is a repeated block
            if current_char == previous_char:
                length += 1

            # if the colours are different, break and reset
            else:
                val = encode(length, previous_char)
                data.append(val)
                length = 1
                previous_char = current_char
            
            # we only have 4 bits for len, so also break if we max out
            if current_char == 16:
                val = encode(length, previous_char)
                data.append(val)
                length = 1
                previous_char = current_char

            if (i == SCREEN_WIDTH - 1) and (j == SCREEN_HEIGHT-1):
                data.append(encode(length, previous_char))  # last encoding
                data.append(0)  # end of the encoding (null byte)
                break

        # this data is hardcoded text
        elif (mode == "ENC_TEXT"):

            # encode next string in TEXT_TO_ENCODE

            diff = 177 if (text_enc_index == 0) else 197
            # advance
            text_index = (i * SCREEN_WIDTH + j) - diff
            # gives character to encode
            val = TEXT_TO_ENCODE[text_enc_index][text_index]

            # shift four and set bit five
            out_byte = data.append(CHAR_CODE[val] << 4 | 0x08)

            if (text_index == (len(TEXT_TO_ENCODE[text_enc_index]) - 1)):
                # entire string encoded, switch back to color mode (for next iteration)
                mode = "ENC_COL"
                text_enc_index += 1