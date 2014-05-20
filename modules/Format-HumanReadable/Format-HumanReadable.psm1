### Format-HumanReadable.ps1 ###
### Script must be published with License and Readme

# Auto formats size to highest formats
# Make sure to input number and digital storage extension
# IE Format-HumanReadable 1024TB = Returns 1PB

Function Format-HumanReadable 
        {
            param ($size)
            switch ($size) 
            {
                {$_ -ge 1PB}{"{0:#.#'PB'}" -f ($size / 1PB); break}
                {$_ -ge 1TB}{"{0:#.#'TB'}" -f ($size / 1TB); break}
                {$_ -ge 1GB}{"{0:#.#'GB'}" -f ($size / 1GB); break}
                {$_ -ge 1MB}{"{0:#.#'MB'}" -f ($size / 1MB); break}
                {$_ -ge 1KB}{"{0:#'KB'}" -f ($size / 1KB); break}
                default {"{0}" -f ($size) + "B"}
            }
        }
