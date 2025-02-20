task build IMAGE_DIR=${{ matrix.IMAGE_DIR }} \
            IMAGE_NAME=${{ env.IMAGE_NAME }} \
            IMAGE_TAG=${{ env.IMAGE_TAG }} \
            -- --cache-from=ghcr.io/${{ github.repository_owner }}/${{ env.IMAGE_NAME }}:${{ env.IMAGE_TAG }}