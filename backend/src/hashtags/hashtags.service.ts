import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class HashtagsService {
    constructor(private prisma: PrismaService) { }

    async create(name: string) {
        try {
            return await this.prisma.hashtag.create({
                data: { name },
            });
        } catch (error) {
            if (error.code === 'P2002') {
                throw new Error('Hashtag already exists');
            }
            throw error;
        }
    }
    async findAll() {
        return this.prisma.hashtag.findMany();
    }

}
