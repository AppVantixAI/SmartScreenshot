#!/usr/bin/env python3
import subprocess

def create_menu_icon():
    """Create menu bar icons for SmartScreenshot"""
    
    # Create a simple camera icon for the menu bar
    svg_content = '''<?xml version="1.0" encoding="UTF-8"?>
<svg width="32" height="32" xmlns="http://www.w3.org/2000/svg">
  <!-- Camera icon for menu bar -->
  <rect x="4" y="8" width="24" height="16" fill="white" stroke="white" stroke-width="1" rx="3" ry="3"/>
  <circle cx="16" cy="16" r="6" fill="black" stroke="white" stroke-width="1"/>
  <circle cx="16" cy="16" r="4" fill="#6495ED"/>
  <rect x="12" y="6" width="8" height="2" fill="white" rx="1" ry="1"/>
</svg>'''
    
    # Write SVG to file
    with open("temp_icon/menu_icon.svg", "w") as f:
        f.write(svg_content)
    
    # Create light and dark versions
    try:
        # Light version (for dark menu bar)
        subprocess.run([
            "sips", "-s", "format", "png", "temp_icon/menu_icon.svg", 
            "--out", "temp_icon/LightMenuBar-16w.png"
        ], check=True)
        
        # Create 32w version by resizing the 16w version
        subprocess.run([
            "sips", "-z", "32", "32", "temp_icon/LightMenuBar-16w.png",
            "--out", "temp_icon/LightMenuBar-32w.png"
        ], check=True)
        
        # Dark version (for light menu bar) - invert colors
        dark_svg = '''<?xml version="1.0" encoding="UTF-8"?>
<svg width="32" height="32" xmlns="http://www.w3.org/2000/svg">
  <!-- Camera icon for menu bar (dark version) -->
  <rect x="4" y="8" width="24" height="16" fill="black" stroke="black" stroke-width="1" rx="3" ry="3"/>
  <circle cx="16" cy="16" r="6" fill="white" stroke="black" stroke-width="1"/>
  <circle cx="16" cy="16" r="4" fill="#6495ED"/>
  <rect x="12" y="6" width="8" height="2" fill="black" rx="1" ry="1"/>
</svg>'''
        
        with open("temp_icon/menu_icon_dark.svg", "w") as f:
            f.write(dark_svg)
        
        subprocess.run([
            "sips", "-s", "format", "png", "temp_icon/menu_icon_dark.svg", 
            "--out", "temp_icon/DarkMenuBar-16w.png"
        ], check=True)
        
        subprocess.run([
            "sips", "-z", "32", "32", "temp_icon/DarkMenuBar-16w.png",
            "--out", "temp_icon/DarkMenuBar-32w.png"
        ], check=True)
        
        print("Menu bar icons created successfully!")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"Error creating menu icons: {e}")
        return False

if __name__ == "__main__":
    create_menu_icon()
