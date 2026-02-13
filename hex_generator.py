from abc import ABC, abstractmethod

class Calchecksum:
    """Calculates the checksum for an Intel HEX record."""
    @staticmethod
    def checksum(byte_list):
        """
        Calculates the standard Intel HEX checksum.
        Args:
            byte_list (list): A list of hex string bytes, excluding the initial ':'
        Returns:
            str: The 2-character uppercase checksum as a string.
        """
        total = sum(int(val, 16) for val in byte_list[:-1]) # Exclude the dummy checksum placeholder
        complement = (~total + 1)
        checksum_val = complement & 0xFF
        return f"{checksum_val:02X}"

class HexGenerator(ABC):
    """Abstract base class for different HEX generation modules."""
    
    def __init__(self, input_file, output_file):
        self.input_file = input_file
        self.output_file = output_file
        with open(self.input_file, "r", encoding="utf-8") as file:
            self.content = file.readlines()

    @abstractmethod
    def generate_hex(self):
        """Finds the relevant blocks and generates HEX data."""
        pass

    def _write_hex_lines(self, hex_lines):
        """Appends formatted HEX lines to the output file."""
        with open(self.output_file, "a", encoding="utf-8") as file_out:
            for line in hex_lines:
                if len(line) > 1: # Ensure it's a data line
                    checksum = Calchecksum.checksum(line)
                    line[-1] = checksum # Place checksum in the last position
                    file_out.write(f":{''.join(line)}\n")

class PanelCombinedTH(HexGenerator):
    """Generates HEX configuration for combined Panel (Switch + Output)."""

    def generate_hex(self):
        """Processes the input file to find and convert all Panel blocks."""
        panel_address_map = {f"Panel-{i:02d}": 0x1000 + (i - 1) * 0x100 for i in range(1, 49)}

        i = 0
        while i < len(self.content):
            row = self.content[i].strip()
            if row.startswith("<Panel-") and not row.startswith("</"):
                panel_name = row.strip("<>")
                panel_end = self._find_closing_tag(i, f"</{panel_name}>")
                if not panel_end:
                    i += 1
                    continue

                base_addr = panel_address_map.get(panel_name)
                if base_addr is None:
                    i = panel_end + 1
                    continue

                self._process_panel_block(i, panel_end, base_addr)
                i = panel_end + 1
            else:
                i += 1
    
    def _find_closing_tag(self, start_index, tag):
        """Finds the line index of a closing tag."""
        for j in range(start_index + 1, len(self.content)):
            if self.content[j].strip() == tag:
                return j
        return None

    def _process_panel_block(self, start, end, base_addr):
        """Processes Switch and Output sections within a Panel block."""
        switch_start = self._find_closing_tag(start, "<Switch>")
        switch_end = self._find_closing_tag(switch_start, "</Switch>") if switch_start else None
        
        output_start = self._find_closing_tag(start, "<Output>")
        output_end = self._find_closing_tag(output_start, "</Output>") if output_start else None

        if switch_start and switch_end:
            self._generate_switch_hex(switch_start, switch_end, base_addr)

        if output_start and output_end:
            self._generate_output_hex(output_start, output_end, base_addr + 0x0050)

    def _generate_switch_hex(self, start, end, base_addr):
        """Generates HEX data for the Switch section."""
        switch_map = {f"SW-{i:02d}": (i - 1) * 4 for i in range(1, 21)}
        action_map = {
            "LAMP": ("01", "00"), "BELL": ("03", "00"), "FAN-ON/OFF": ("06", "00"),
            "FAN-UP": ("07", "00"), "FAN-DOWN": ("08", "00"), "CURTAIN-OPEN": ("04", "00"),
            "CURTAIN-CLOSE": ("05", "00"), "DIMMER-ON/OFF": ("15", "00"),
            "DIMMER-UP": ("09", "00"), "DIMMER-DOWN": ("0A", "00"),
            "DIMMER-RLOVR": ("0B", "00"), "MASTER": ("02", "00"),
            "OCCUPANCY": ("0C", "00"), "DND": ("0D", "00"), "MMR": ("0E", "00"),
            "LAUNDRY": ("0F", "00"), "SCENE": ("10", "00"), "SCENE-OFF": ("17", "00"),
            "SCENE-TOGGLE": ("18", "00"), "THERMOSTAT-ON/OFF": ("11", "00"),
            "THERMOSTAT-FAN": ("12", "00"), "THERMOSTAT-T-UP": ("13", "00"),
            "THERMOSTAT-T-DN": ("14", "00"), "THERMOSTAT-MODE": ("16", "00"),
        }
        param_map = {
            "LAMP": "00", "BELL": "03", "FAN-ON/OFF": "51", "FAN-UP": "52",
            "FAN-DOWN": "52", "CURTAIN-OPEN": "41", "CURTAIN-CLOSE": "42",
            "DIMMER-ON/OFF": "61", "DIMMER-UP": "62", "DIMMER-DOWN": "62",
            "DIMMER-RLOVR": "62", "MASTER": "02", "OCCUPANCY": "03", "DND": "04",
            "MMR": "05", "LAUNDRY": "06", "SCENE": "81", "SCENE-OFF": "81",
            "SCENE-TOGGLE": "81", "THERMOSTAT-ON/OFF": "71", "THERMOSTAT-FAN": "72",
            "THERMOSTAT-T-UP": "73", "THERMOSTAT-T-DN": "73", "THERMOSTAT-MODE": "75",
        }

        hex_data = [
            ["10", f"{(base_addr + i * 0x10) >> 8:02X}", f"{(base_addr + i * 0x10) & 0xFF:02X}", "00"] + ["00"] * 16 + ["00"]
            for i in range(5)
        ]

        for i in range(start + 1, end):
            parts = self.content[i].strip().split(",")
            if len(parts) < 3: continue

            switch, action, param = parts[:3]
            address = switch_map.get(switch)
            if address is None: continue

            data1, data2 = action_map.get(action, ("00", "00"))
            data3 = f"{int(param):02X}" if param.strip().isdigit() else "00"
            data4 = param_map.get(action, "00")
            
            row, col = address // 16, (address % 16) + 4
            hex_data[row][col:col + 4] = [data1, data2, data3, data4]
        
        self._write_hex_lines(hex_data)

    def _generate_output_hex(self, start, end, base_addr):
        """Generates HEX data for the Output section."""
        address_map = {f"OD-{i:02d}": (i - 1) * 8 for i in range(1, 17)}
        type_map = {"RLY": "11", "DIM": "22", "ANA": "33"}
        action_map = {
            "LAMP": "00", "BELL": "01", "OCCUPANCY": "03", "FAN-BLDC": "50",
            "FAN-LOW": "51", "FAN-MID": "52", "FAN-HIGH": "53", "CURTAIN-OPEN": "41",
            "CURTAIN-CLOSE": "42", "THERMOSTAT-LOW": "71", "THERMOSTAT-MID": "72",
            "THERMOSTAT-HIGH": "73", "THERMOSTAT-VALVE": "74", "DIMMER": "61"
        }

        hex_lines = [
            ["10", f"{(base_addr + i * 0x10) >> 8:02X}", f"{(base_addr + i * 0x10) & 0xFF:02X}", "00"] + ["00"] * 16 + ["00"]
            for i in range(8)
        ]

        for i in range(start + 1, end):
            parts = self.content[i].strip().split(",")
            if len(parts) < 5: continue

            device, dev_type, action, param, timeout = parts[:5]
            address = address_map.get(device)
            if address is None: continue

            data1 = type_map.get(dev_type, "00")
            data2 = "00"
            data3 = f"{int(param):02X}" if param.isdigit() else "00"
            data4 = action_map.get(action, "00")
            data5 = f"{int(timeout) & 0xFF:02X}" if timeout.isdigit() else "00"
            data6 = f"{(int(timeout) >> 8) & 0xFF:02X}" if timeout.isdigit() else "00"

            row, col = address // 16, (address % 16) + 4
            if row < len(hex_lines) and col + 5 < len(hex_lines[row]):
                hex_lines[row][col:col + 6] = [data1, data2, data3, data4, data5, data6]
        
        self._write_hex_lines(hex_lines)

def main(input_file, output_file):
    """
    Main function to run the HEX generation process.
    This script converts a proprietary text format into an Intel HEX file.
    """
    # Clear output file
    with open(output_file, 'w', encoding="utf-8") as f:
        pass

    # Process different parts of the configuration
    panel_converter = PanelCombinedTH(input_file, output_file)
    panel_converter.generate_hex()
    
    # Add other converters as needed, for example:
    # SceneTH(input_file, output_file).generate_hex()
    # InMainTH(input_file, output_file).generate_hex()
    # ModbusTH(input_file, output_file).generate_hex()
    # BMSInfoTH(input_file, output_file).generate_hex()
    WIFIConnTH(input_file, output_file).generate_hex()

    # Write End Of File record
    with open(output_file, "a", encoding="utf-8") as f:
        f.write(":00000001FF\n")
    
    print(f"File conversion complete. Output written to {output_file}")

class WIFIConnTH(HexGenerator):
    """Generates HEX configuration for WiFi and MQTT connectivity."""

    def generate_hex(self):
        """Processes the input file to find and convert the Connectivity block."""
        try:
            content_str = "".join(self.content)
            start_index = content_str.find("<Connectivity>")
            end_index = content_str.find("</Connectivity>")

            if start_index == -1 or end_index == -1:
                return

            connectivity_block = content_str[start_index:end_index]
            self._process_connectivity_block(connectivity_block, 0x4000)

        except ValueError:
            return

    def _process_connectivity_block(self, block, base_addr):
        """Processes the Connectivity section."""
        
        def extract_value(key):
            try:
                start = block.find(key) + len(key)
                end = block.find("\n", start)
                return block[start:end].strip().split(',')[1]
            except:
                return ""

        broker_addr = extract_value("MQTTBrokerAddress,")
        username = extract_value("UserName,")
        password = extract_value("Password,")
        port_str = extract_value("MQTTPort,")
        
        port = int(port_str) if port_str.isdigit() else 0

        hex_lines = []

        # MQTT Broker Address (32 bytes at 0x4000)
        hex_lines.extend(self._create_string_hex_lines(base_addr, broker_addr, 32))

        # Username (32 bytes at 0x4020)
        hex_lines.extend(self._create_string_hex_lines(base_addr + 32, username, 32))

        # Password (32 bytes at 0x4040)
        hex_lines.extend(self._create_string_hex_lines(base_addr + 64, password, 32))

        # MQTTPort (2 bytes at 0x4060)
        addr = base_addr + 96
        hex_lines.append(
            ["02", f"{(addr) >> 8:02X}", f"{(addr) & 0xFF:02X}", "00", f"{port & 0xFF:02X}", f"{(port >> 8) & 0xFF:02X}", "00"]
        )

        self._write_hex_lines(hex_lines)

    def _create_string_hex_lines(self, base_addr, text, length):
        """Creates HEX lines for a padded ASCII string."""
        padded_text = text.ljust(length, '\0')
        hex_values = [f"{ord(c):02X}" for c in padded_text]
        
        lines = []
        for i in range(0, length, 16):
            chunk = hex_values[i:i+16]
            addr = base_addr + i
            line = ["10", f"{addr >> 8:02X}", f"{addr & 0xFF:02X}", "00"] + chunk + ["00"]
            lines.append(line)
        return lines

if __name__ == '__main__':
    import sys
    import os

    if len(sys.argv) > 1:
        input_path = sys.argv[1]
    else:
        # Fallback to a default name if no argument is provided.
        input_path = 'config.txt'
        print(f"Usage: python {sys.argv[0]} <input_file.txt>")
        print(f"No input file provided. Trying with default '{input_path}'")
        
    if not os.path.exists(input_path):
        print(f"Error: Input file not found at '{input_path}'")
        sys.exit(1)

    output_path = os.path.splitext(input_path)[0] + '.hex'
    
    main(input_path, output_path)
