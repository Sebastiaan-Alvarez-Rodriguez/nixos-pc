bool encoder_update_user(uint8_t index, bool clockwise) {
    if (index == 0) { // Left side encoder
        if (clockwise) {
            tap_code(MS_WHLR); // Smooth Scroll Right
        } else {
            tap_code(MS_WHLL); // Smooth Scroll Left
        }
    } else if (index == 1) { // Right side encoder
        if (clockwise) {
            tap_code(MS_WHLD); // Scroll Down
        } else {
            tap_code(MS_WHLU); // Scroll Up
        }
    }
    return false; // Return false to stop the default PageUp/PageDown from firing
    // if (clockwise) {
    //     tap_code(MS_WHLR);
    // } else {
    //     tap_code(MS_WHLL);
    // }
    // return false;
}
