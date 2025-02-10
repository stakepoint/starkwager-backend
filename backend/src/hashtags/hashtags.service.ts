import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class HashtagsService {
  constructor(private prisma: PrismaService) {}

  async create(name: string) {
    const hashtag = await this.prisma.hashtag.create({
      data: { name },
    });
    return hashtag;
  }
  async findAll() {
    return this.prisma.hashtag.findMany();
  }
}
